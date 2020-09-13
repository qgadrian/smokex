defmodule Smokex.PlanDefinitions.Scheduler do
  @moduledoc """
  This module creates a new entry in the Quantum application with the cron
  sentence present in a plandefinition.
  """
  use Quantum, otp_app: :smokex

  require Logger

  alias Smokex.Limits
  alias Smokex.Users.User
  alias Smokex.PlanDefinition
  alias Smokex.PlanExecution
  alias Smokex.PlanExecutions
  alias Smokex.Oban.PlanExecutionWorker, as: JobWorker

  @doc """
  Creates a job schedule with the plan definition cron sentence.
  """
  @spec create_scheduled_job(PlanDefinition.t()) :: :ok
  def create_scheduled_job(%PlanDefinition{cron_sentence: nil}), do: :ok

  def create_scheduled_job(
        %PlanDefinition{id: plan_definition_id, cron_sentence: cron_sentence} = plan_definition
      ) do
    {:ok, cron_sentence} = Crontab.CronExpression.Parser.parse(cron_sentence)

    __MODULE__.new_job()
    # TODO Find a solution to this, atoms are limited and this can cause problems in the future
    |> Quantum.Job.set_name(:"#{plan_definition_id}")
    |> Quantum.Job.set_schedule(cron_sentence)
    |> Quantum.Job.set_task(fn -> __MODULE__.enqueue_job(plan_definition) end)
    |> __MODULE__.add_job()
  end

  @doc """
  Updates the scheduled job schedule of the given plan definition.

  If no schedule job is present, creates a new one.
  """
  @spec update_scheduled_job(PlanDefinition.t()) :: :ok
  def update_scheduled_job(%PlanDefinition{id: plan_definition_id} = plan_definition) do
    Logger.info("Update scheduled job #{plan_definition_id}")

    :ok = __MODULE__.delete_job(:"#{plan_definition_id}")
    __MODULE__.create_scheduled_job(plan_definition)
  end

  @doc """
  Enqueues a new job that will be executed.

  TODO create a queue for jobs to be executed immediately.

  Keep in mind that in order to run the job, the job will need to be next in
  the execution queue and a worker should be ready to take.
  it.
  """
  @spec enqueue_job(PlanDefinition.t(), User.t() | nil) ::
          {:ok, number} | {:error, Ecto.Changeset.t()}
  def enqueue_job(plan_definition, user_or_nil \\ nil)

  def enqueue_job(%PlanDefinition{} = plan_definition, nil) do
    insert_job(nil, plan_definition)
  end

  @spec enqueue_job(PlanDefinition.t()) :: {:ok, number} | {:error, Ecto.Changeset.t()}
  def enqueue_job(%PlanDefinition{} = plan_definition, %User{} = user) do
    insert_job(user, plan_definition)
  end

  #
  # Private functions
  #
  #

  defp build_job_spec(%PlanExecution{id: plan_execution_id}, %User{id: user_id}) do
    JobWorker.new(%{
      user_id: user_id,
      plan_execution_id: plan_execution_id
    })
  end

  defp build_job_spec(%PlanExecution{id: plan_execution_id}, nil) do
    JobWorker.new(%{
      user_id: nil,
      plan_execution_id: plan_execution_id
    })
  end

  @spec insert_job(User.t() | nil, PlanDefinition.t()) :: {:ok, number} | {:error, term}
  defp insert_job(user_or_nil, %PlanDefinition{} = plan_definition) do
    with {:ok, %PlanExecution{id: plan_execution_id} = plan_execution} <-
           PlanExecutions.create_plan_execution(user_or_nil, plan_definition),
         job_spec <- build_job_spec(plan_execution, user_or_nil),
         {:ok, %Oban.Job{args: %{plan_execution_id: ^plan_execution_id}}} <-
           Oban.insert(job_spec) do
      Logger.info("Created scheduled job for execution #{inspect(plan_execution_id)}")
      {:ok, plan_execution_id}
    else
      {:error, changeset} = error ->
        Logger.error("Error creating scheduled job: #{inspect(changeset)}")
        error
    end
  end
end
