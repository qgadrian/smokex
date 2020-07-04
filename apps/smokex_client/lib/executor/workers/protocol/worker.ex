defprotocol SmokexClient.Worker do
  @doc "Parses a step plan"
  @fallback_to_any true
  # TODO replace any with the supported types
  @spec execute(any, Smokex.PlanExecution.t()) :: atom
  def execute(step, plan_execution)
end

defimpl SmokexClient.Worker, for: Any do
  @spec execute(any, Smokex.PlanExecution.t()) :: atom
  def execute(_step, _plan_execution) do
    # TODO do not throw are return error flow tuples
    throw({:error, "Unknown step type"})
  end
end
