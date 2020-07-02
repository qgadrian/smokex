defmodule Smokex.Repo.Migrations.CreatePlansExecutionsStepsResults do
  use Ecto.Migration

  def change do
    create table(:plans_executions_steps_results) do
      add(:plan_execution_id, references(:plans_executions))

      add(:action, :string, null: false)
      add(:host, :string, null: true)
      add(:failed_assertions, {:array, :map}, null: false)
      add(:result, :string, null: false)
    end
  end
end
