defmodule Smokex.Repo.Migrations.CreatePlansExecutions do
  use Ecto.Migration

  def change do
    create table(:plans_executions) do
      add(:status, :string, null: false)
      add(:plan_definition_id, references(:plans_definitions))
      timestamps()
    end
  end
end
