defmodule Smokex.Repo.Migrations.CreateOrganizationsUsers do
  use Ecto.Migration

  def change do
    create table(:organizations_users) do
      add(:organization_id, references(:organizations), null: false)
      add(:user_id, references(:users), null: false)

      timestamps()
    end

    create unique_index(:organizations_users, [:organization_id, :user_id])
  end
end
