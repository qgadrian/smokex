defmodule SmokexClient.Workers.CleanerWorker do
  use Oban.Worker, queue: :scheduled_stacks

  require Logger

  alias Smokex.PlanExecutionsCleaner

  @doc """
  Runs the clean old executions task.
  """
  @impl Oban.Worker
  def perform(%Oban.Job{
        args: _args,
        scheduled_at: _scheduled_at
      }) do
    Logger.info("Start cleaning old executions")

    {number_of_deletions, _} = PlanExecutionsCleaner.clear_old_executions_from_organizations()

    Logger.info("Deleted #{number_of_deletions} executions and their results")
  end
end
