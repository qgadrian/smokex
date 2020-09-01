defmodule Smokex.Repo.Migrations.AddOrganizations do
  use Ecto.Migration

  def change do
    create table(:organizations) do
      add(:name, :string, null: false)
      add(:subscription_expires_at, :utc_datetime)

      timestamps()
    end
  end
end
