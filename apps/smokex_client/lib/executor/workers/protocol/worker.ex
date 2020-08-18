defprotocol SmokexClient.Worker do
  alias SmokexClient.ExecutionContext

  @doc "Parses a step plan"
  @fallback_to_any true
  # TODO replace any with the supported types
  @spec execute(any, Smokex.PlanExecution.t(), ExecutionContext.t()) :: ExecutionContext.t()
  def execute(step, plan_execution, execution_context \\ %ExecutionContext{})
end

defimpl SmokexClient.Worker, for: Any do
  @spec execute(any, Smokex.PlanExecution.t(), ExecutionContext.t()) :: atom
  def execute(_step, _plan_execution, _execution_context) do
    # TODO do not throw are return error flow tuples
    throw({:error, "Unknown step type"})
  end
end
