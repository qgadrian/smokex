defprotocol SmokexClient.Worker do
  @doc "Parses a step plan"
  @fallback_to_any true
  @spec execute(any) :: atom
  def execute(step)
end

defimpl SmokexClient.Worker, for: Any do
  @spec execute(any) :: atom
  def execute(_step) do
    throw({:error, "Unknown step type"})
  end
end
