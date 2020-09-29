defimpl SmokexClient.Worker, for: Smokex.Step.Request do
  require Logger

  alias SmokexClient.Validator
  alias SmokexClient.ExecutionContext

  alias Smokex.Step.Request.SaveFromResponse
  alias Smokex.Step.Request
  alias Smokex.PlanExecution
  alias SmokexClient.Step.HttpClient

  alias Smokex.Results.HTTPResponse
  alias Smokex.Step.Response.ResponseBuilder

  alias SmokexClient.Utils.StepVarsReplacer

  @spec execute(Request.t(), PlanExecution.t(), ExecutionContext.t()) ::
          ExecutionContext.t() | no_return
  def execute(
        %Request{} = step,
        %PlanExecution{id: plan_execution_id, plan_definition_id: plan_definition_id} =
          plan_execution,
        %ExecutionContext{halt_on_error: halt_on_error} = execution_context
      ) do
    Logger.debug("Start execution #{inspect(step)}")

    step = StepVarsReplacer.process_step_variables_(step, execution_context)

    started_at = DateTime.utc_now()

    case HttpClient.request(step) do
      {:ok, http_client_response} ->
        response =
          ResponseBuilder.build(http_client_response,
            started_at: started_at,
            finished_at: DateTime.utc_now(),
            plan_execution_id: plan_execution_id
          )

        step.expect
        |> Validator.validate(http_client_response)
        |> process_validation(step, plan_execution, execution_context, response)

      {:error, reason} ->
        process_request_error(step, reason, plan_execution)

        if halt_on_error do
          throw({:error, reason})
        else
          execution_context
        end
    end
  end

  #
  # Private functions
  #

  @spec process_validation(
          Validator.validation_result(),
          Request.t(),
          PlanExecution.t(),
          ExecutionContext.t(),
          Result.t()
        ) :: atom
  defp process_validation(
         validation_result,
         %Request{} = step,
         %PlanExecution{} = plan_execution,
         %ExecutionContext{halt_on_error: halt_on_error, variables: context_variables} =
           execution_context,
         %HTTPResponse{} = response
       ) do
    case validation_result do
      {:error, info, message} ->
        # TODO save in database and notify the result via PubSub
        {:ok, _result} =
          Smokex.Results.create(%{
            plan_execution: plan_execution,
            action: step.action,
            host: step.host,
            response: response,
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
            response: response,
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

  @spec process_request_error(Request.t(), term, PlanExecution.t()) :: :ok
  defp process_request_error(%Request{} = step, reason, %PlanExecution{} = plan_execution) do
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
      json_body = response_body["json"] || response_body

      case ExJSONPath.eval(json_body, save_from_response.json_path) do
        {:ok, [value_from_response]} ->
          {save_from_response.variable_name, value_from_response}

        _ ->
          {save_from_response.variable_name, nil}
      end
    end)
    |> Map.new()
  end
end
