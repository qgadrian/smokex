defmodule SmokexClient.ExecutionState do
  use Agent

  def start_link() do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  @doc "Inserts an execution result"
  def put_result(result) do
    Agent.update(__MODULE__, &(&1 ++ [result]))
  end

  @doc "Get all execution results"
  def get_results() do
    Agent.get(__MODULE__, & &1)
  end
end
