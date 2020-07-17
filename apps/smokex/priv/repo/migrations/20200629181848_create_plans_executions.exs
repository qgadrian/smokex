defmodule Smokex.Repo.Migrations.CreatePlansExecutions do
  use Ecto.Migration

  def change do
    create table(:plans_executions) do
      add(:status, :string, null: false)
      add(:total_executions, :integer, null: true)

      add(:plan_definition_id, references(:plans_definitions))

      add(:started_at, :naive_datetime)
      add(:finished_at, :naive_datetime)

      timestamps()
    end
  end
end
