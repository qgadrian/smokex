defimpl SmokexClient.Worker, for: Smokex.Step.Request do
  alias SmokexClient.Validator
  alias SmokexClient.ExecutionState

  alias Smokex.Step.Request.SaveFromResponse
  alias Smokex.Step.Request
  alias Smokex.Result
  alias Smokex.PlanExecution

  alias SmokexClient.Utils.StepVarsReplacer

  @type validation_result :: {:ok, any} | {:error, any, String.t()}

  @spec execute(Request.t(), PlanExecution.t()) :: atom | no_return
  def execute(%Request{} = step, %PlanExecution{} = plan_execution) do
    step = StepVarsReplacer.process_step_variables_(step)

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
        |> process_validation(step, plan_execution)

      {:error, %HTTPoison.Error{reason: reason}} ->
        process_request_error(step, reason, plan_execution)
        throw({:error, reason})
    end
  end

  @spec get_body(String.t() | map, atom) :: String.t()
  defp get_body(%{}, "get"), do: ""
  defp get_body(body, _action) when is_binary(body), do: body
  defp get_body(body, _action), do: Jason.encode!(body)

  @spec process_validation(validation_result, Request.t(), PlanExecution.t()) :: atom
  defp process_validation(validation_result, %Request{} = step, %PlanExecution{} = plan_execution) do
    case validation_result do
      {:error, info, message} ->
        # TODO save in database and notify the result via PubSub
        {:ok, result} =
          Smokex.Results.create(%{
            plan_execution: plan_execution,
            action: step.action,
            host: step.host,
            failed_assertions: [info],
            result: :error
          })

        throw({:error, message})

      {:ok, response_body} ->
        save_from_response(step.save_from_response, response_body)

        # TODO save in database and notify the result via PubSub
        {:ok, result} =
          Smokex.Results.create(%{
            plan_execution: plan_execution,
            action: step.action,
            host: step.host,
            result: :ok
          })
    end
  end

  @spec process_request_error(Request.t(), any, PlanExecution.t()) :: :ok
  defp process_request_error(%Request{} = step, reason, plan_execution) do
    case reason do
      :nxdomain ->
        # TODO save in database and notify the result via PubSub
        {:ok, result} =
          Smokex.Results.create(%{
            plan_execution: plan_execution,
            action: step.action,
            host: step.host,
            failed_assertions: [%{error: "Invalid host"}],
            result: :error
          })

      nil ->
        # TODO save in database and notify the result via PubSub
        {:ok, result} =
          Smokex.Results.create(%{
            plan_execution: plan_execution,
            action: step.action,
            host: step.host,
            result: :error
          })

      _other ->
        # TODO save in database and notify the result via PubSub
        {:ok, result} =
          Smokex.Results.create(%{
            plan_execution: plan_execution,
            action: step.action,
            host: step.host,
            failed_assertions: [%{error: reason}],
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
