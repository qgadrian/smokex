defmodule Smokex.Oban.PlanExecutionWorker do
  use Oban.Worker, queue: :plan_executions

  require Logger

  alias Smokex.PlanExecution
  alias Smokex.PlanExecutions
  alias SmokexWeb.Tracer

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: %{"plan_execution_id" => plan_execution_id, "user_id" => _user_id_or_nil}
      }) do
    Logger.info("Start scheduled job for #{plan_execution_id}")

    with %PlanExecution{} = plan_execution <- PlanExecutions.get(plan_execution_id),
         :ok <- Tracer.trace_plan_execution(plan_execution),
         {:ok, _plan_execution} <- SmokexClient.Executor.execute(plan_execution) do
      Logger.info("Scheduled job for #{plan_execution_id} done!")

      :ok
    else
      nil ->
        Logger.error("Plan definition not found: #{plan_execution_id}")
        :error

      {:error, :reached_free_limit} ->
        Logger.error("Plan execution cannot be run because of limit: #{plan_execution_id}")
        :ok

      error ->
        Logger.error("Error executing scheduled job: #{inspect(error)}")
        :error
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{
        args: args
      }) do
    Logger.error("Job args do not match: #{inspect(args)}")
  end
end
