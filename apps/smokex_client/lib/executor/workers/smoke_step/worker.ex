defimpl SmokexClient.Worker, for: Smokex.Step.Request do
  alias SmokexClient.Validator
  alias SmokexClient.Printer.SmokeStep, as: Printer
  alias SmokexClient.ExecutionState

  alias Smokex.Step.Request.SaveFromResponse
  alias Smokex.Step.Request
  alias Smokex.Result

  alias SmokexClient.Utils.StepVarsReplacer

  @type validation_result :: {:ok, any} | {:error, any, String.t()}

  @spec execute(Request.t()) :: atom | no_return
  def execute(%Request{} = step) do
    step = StepVarsReplacer.process_step_variables_(step)

    Printer.print_step_info(step)

    body = get_body(step.body, step.action)

    # SSL issue in Erlang 19: https://bugs.erlang.org/browse/ERL-192
    options = [
      params: Map.to_list(step.query),
      ssl: [
        {:versions, [:"tlsv1.2"]}
      ],
      recv_timeout: step.opts[:timeout] || Application.get_env(:smokex_client, :timeout),
      hackney: [:insecure]
    ]

    headers = Map.to_list(step.headers)

    response = HTTPoison.request(step.action, step.host, body, headers, options)

    case response do
      {:ok, response} ->
        step.expect
        |> Validator.validate(response)
        |> process_validation(step)

      {:error, %HTTPoison.Error{reason: reason}} ->
        process_request_error(step, reason)
        throw({:error, reason})
    end
  end

  @spec get_body(String.t() | map, atom) :: String.t()
  defp get_body(%{}, "get"), do: ""
  defp get_body(body, _action) when is_binary(body), do: body
  defp get_body(body, _action), do: Jason.encode!(body)

  @spec process_validation(validation_result, Request.t()) :: atom
  defp process_validation(validation_result, %Request{} = step) do
    case validation_result do
      {:error, info, message} ->
        ExecutionState.put_result(%Result{
          action: step.action,
          host: step.host,
          failed_assertions: info,
          result: :error
        })

        {:ok, result} =
          Smokex.Results.create(%{
            action: step.action,
            host: step.host,
            failed_assertions: [info],
            result: :error
          })

        IO.inspect(result)

        throw({:error, message})

      {:ok, response_body} ->
        save_from_response(step.save_from_response, response_body)

        ExecutionState.put_result(%Result{
          action: step.action,
          host: step.host,
          result: :ok
        })
    end
  end

  @spec process_request_error(Request.t(), any) :: :ok
  defp process_request_error(%Request{} = step, reason) do
    case reason do
      :nxdomain ->
        ExecutionState.put_result(%Result{
          action: step.action,
          host: step.host,
          failed_assertions: %{error: "Invalid host"},
          result: :error
        })

      nil ->
        ExecutionState.put_result(%Result{
          action: step.action,
          host: step.host,
          result: :error
        })

      _other ->
        ExecutionState.put_result(%Result{
          action: step.action,
          host: step.host,
          failed_assertions: %{error: reason},
          result: :error
        })
    end
  end

  @spec save_from_response(list(SaveFromResponse.t()), String.t()) :: :ok
  defp save_from_response(save_from_responses, response_body) do
    Enum.map(save_from_responses, fn save_from_response ->
      json_path_as_list = String.split(save_from_response.json_path, ".")
      value_from_response = get_in(response_body, json_path_as_list)

      # TODO avoid saving variables in env
      # TODO raise assertion error when the value from response was not found
      Application.put_env(
        :smokex_client,
        save_from_response.variable_name,
        value_from_response
      )
    end)
  end
end
