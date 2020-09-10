defmodule Smokex.Repo.Migrations.CreateSlackUsersIntegrations do
  use Ecto.Migration

  def change do
    create table(:slack_integrations) do
      add(:token, :string, null: false)
      add(:organization_id, references(:organizations, on_delete: :delete_all))
      add(:options, :map, null: false)

      timestamps()
    end

    create(unique_index(:slack_integrations, [:token, :organization_id]))
  end
end
