defmodule Smokex.Repo.Migrations.CreatePlansExecutions do
  use Ecto.Migration

  def change do
    create table(:plans_executions, primary_key: false) do
      add :id, :uuid, primary_key: true

      add(:status, :string, null: false)
      add(:total_executions, :integer, null: true)

      add(
        :plan_definition_id,
        references(:plans_definitions, type: :uuid, on_delete: :delete_all),
        null: false
      )

      add(:trigger_user_id, references(:users), null: true)

      add(:started_at, :naive_datetime_usec)
      add(:finished_at, :naive_datetime_usec)

      timestamps()
    end
  end
end
