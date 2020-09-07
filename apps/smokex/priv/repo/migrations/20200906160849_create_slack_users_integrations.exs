defmodule Smokex.Repo.Migrations.CreateSlackUsersIntegrations do
  use Ecto.Migration

  def change do
    create table(:slack_users_integrations) do
      add(:token, :string, null: false)
      add(:user_id, references(:users, on_delete: :delete_all))
      add(:options, :map, null: false)

      timestamps()
    end

    create(unique_index(:slack_users_integrations, [:token, :user_id]))
  end
end
