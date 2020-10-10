defimpl SmokexClient.Worker, for: Smokex.Step.Request do
  require Logger

  alias Smokex.PlanExecution
  alias Smokex.Results.HTTPResponse
  alias Smokex.Step.Request
  alias Smokex.Step.Request.SaveFromResponse
  alias Smokex.Step.Response.ResponseBuilder
  alias SmokexClient.ExecutionContext
  alias SmokexClient.Step.HttpClient
  alias SmokexClient.Utils.StepVarsReplacer
  alias SmokexClient.Validator
  alias SmokexClient.Validator.ValidationContext

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
          ValidatorContext.t(),
          Request.t(),
          PlanExecution.t(),
          ExecutionContext.t(),
          HTTPResponse.t()
        ) :: atom
  defp process_validation(
         %ValidationContext{validation_errors: []},
         %Request{} = step,
         %PlanExecution{} = plan_execution,
         %ExecutionContext{variables: context_variables} = execution_context,
         %HTTPResponse{body: response_body} = response
       ) do
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

  defp process_validation(
         %ValidationContext{validation_errors: validation_errors},
         %Request{} = step,
         %PlanExecution{} = plan_execution,
         %ExecutionContext{halt_on_error: halt_on_error, variables: context_variables} =
           execution_context,
         %HTTPResponse{body: response_body} = response
       ) do
    # TODO save in database and notify the result via PubSub
    {:ok, _result} =
      Smokex.Results.create(%{
        plan_execution: plan_execution,
        action: step.action,
        host: step.host,
        response: response,
        failed_assertions: Enum.map(validation_errors, &Map.from_struct/1),
        result: :error
      })

    if halt_on_error do
      throw({:error, "Halting because some expectations were not met"})
    else
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

  @spec save_from_response(list(SaveFromResponse.t()), map | nil) :: map_with_new_variables :: map
  defp save_from_response(_save_from_resposwes, nil), do: %{}

  defp save_from_response(save_from_responses, response_body) when is_binary(response_body) do
    with {:ok, response_body} <- Jason.decode(response_body) do
      save_from_response(save_from_responses, response_body)
    else
      _ ->
        Logger.debug("Error parsing JSON to save response")

        %{}
    end
  end

  defp save_from_response(save_from_responses, response_body) do
    save_from_responses
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
