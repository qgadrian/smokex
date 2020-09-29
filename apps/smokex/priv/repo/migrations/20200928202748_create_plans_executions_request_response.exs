defmodule Smokex.Repo.Migrations.CreatePlansExecutionsRequestResponse do
  use Ecto.Migration

  def change do
    create table(:plans_executions_http_request_responses) do
      add(:result_id, references(:plans_executions_http_request_results), null: false)

      add(:body, :binary, null: true)
      add(:headers, :binary, null: true)
      add(:query, :binary, null: true)
      add(:status, :integer, null: false)

      add(:started_at, :utc_datetime_usec, null: false)
      add(:finished_at, :utc_datetime_usec, null: false)

      timestamps()
    end
  end
end
