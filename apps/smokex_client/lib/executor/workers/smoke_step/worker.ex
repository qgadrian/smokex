defimpl SmokexClient.Worker, for: Smokex.Step.Request do
  require Logger

  alias SmokexClient.Validator
  alias SmokexClient.ExecutionContext

  alias Smokex.Step.Request.SaveFromResponse
  alias Smokex.Step.Request
  alias Smokex.PlanExecution

  alias SmokexClient.Utils.StepVarsReplacer

  @type validation_result :: {:ok, any} | {:error, any, String.t()}

  @spec execute(Request.t(), PlanExecution.t(), ExecutionContext.t()) ::
          ExecutionContext.t() | no_return
  def execute(
        %Request{} = step,
        %PlanExecution{} = plan_execution,
        %ExecutionContext{halt_on_error: halt_on_error} = execution_context
      ) do
    Logger.debug("Executing #{inspect(step)}")

    step = StepVarsReplacer.process_step_variables_(step, execution_context)

    body = get_body(step.body, step.action)

    # SSL issue in Erlang 19: https://bugs.erlang.org/browse/ERL-192
    http_client_options = [
      params: Map.to_list(step.query),
      ssl: [
        {:versions, [:"tlsv1.2"]}
      ],
      recv_timeout: step.opts[:timeout] || Application.get_env(:smokex_client, :timeout),
      hackney: [:insecure]
    ]

    headers = Map.to_list(step.headers)

    response = HTTPoison.request(step.action, step.host, body, headers, http_client_options)

    case response do
      {:ok, response} ->
        step.expect
        |> Validator.validate(response)
        |> process_validation(step, plan_execution, execution_context)

      {:error, %HTTPoison.Error{reason: reason}} ->
        process_request_error(step, reason, plan_execution)

        if halt_on_error do
          throw({:error, reason})
        else
          execution_context
        end
    end
  end

  @spec get_body(String.t() | map, atom) :: String.t()
  defp get_body(%{}, "get"), do: ""
  defp get_body(body, _action) when is_binary(body), do: body
  defp get_body(body, _action), do: Jason.encode!(body)

  @spec process_validation(
          validation_result,
          Request.t(),
          PlanExecution.t(),
          ExecutionContext.t()
        ) :: atom
  defp process_validation(
         validation_result,
         %Request{} = step,
         %PlanExecution{} = plan_execution,
         %ExecutionContext{halt_on_error: halt_on_error, variables: context_variables} =
           execution_context
       ) do
    case validation_result do
      {:error, info, message} ->
        # TODO save in database and notify the result via PubSub
        {:ok, _result} =
          Smokex.Results.create(%{
            plan_execution: plan_execution,
            action: step.action,
            host: step.host,
            failed_assertions: [info],
            result: :error
          })

        if halt_on_error do
          throw({:error, message})
        else
          execution_context
        end

      {:ok, response_body} ->
        # TODO save in database and notify the result via PubSub
        {:ok, _result} =
          Smokex.Results.create(%{
            plan_execution: plan_execution,
            action: step.action,
            host: step.host,
            result: :ok
          })

        updated_context_variables = save_from_response(step.save_from_response, response_body)

        new_context_variables =
          Map.merge(
            context_variables,
            updated_context_variables
          )

        %ExecutionContext{
          execution_context
          | variables: new_context_variables
        }
    end
  end

  @spec process_request_error(Request.t(), any, PlanExecution.t()) :: :ok
  defp process_request_error(%Request{} = step, reason, plan_execution) do
    case reason do
      :nxdomain ->
        # TODO save in database and notify the result via PubSub
        {:ok, _result} =
          Smokex.Results.create(%{
            plan_execution: plan_execution,
            action: step.action,
            host: step.host,
            failed_assertions: [%{error: "Invalid host"}],
            result: :error
          })

      nil ->
        # TODO save in database and notify the result via PubSub
        {:ok, _result} =
          Smokex.Results.create(%{
            plan_execution: plan_execution,
            action: step.action,
            host: step.host,
            result: :error
          })

      _other ->
        # TODO save in database and notify the result via PubSub
        {:ok, _result} =
          Smokex.Results.create(%{
            plan_execution: plan_execution,
            action: step.action,
            host: step.host,
            failed_assertions: [%{error: reason}],
            result: :error
          })
    end
  end

  @spec save_from_response(list(SaveFromResponse.t()), map) :: map
  defp save_from_response(context_variables, response_body) do
    context_variables
    |> Enum.map(fn save_from_response ->
      # TODO use JSON path here
      json_path_as_list = String.split(save_from_response.json_path, ".")
      value_from_response = get_in(response_body["json"], json_path_as_list)

      {save_from_response.variable_name, value_from_response}
    end)
    |> Map.new()
  end
end
