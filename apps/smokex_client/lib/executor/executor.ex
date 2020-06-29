defmodule SmokexClient.Executor do
  alias SmokexClient.ExecutionState
  alias SmokexClient.Worker

  @spec execute(list(struct)) :: atom
  def execute(steps) do
    ExecutionState.start_link()

    try do
      Enum.each(steps, &Worker.execute(&1))
    catch
      {:error, reason} -> {:error, reason}
    end
  end
end
