defmodule Smokex.Repo.Migrations.CreateOrganizationsSecrets do
  use Ecto.Migration

  def change do
    create table(:organizations_secrets) do
      add(:organization_id, references(:organizations), null: false)
      add(:name, :string)
      add(:value, :binary)

      timestamps()
    end

    create unique_index(:organizations_secrets, [:name, :organization_id])
  end
end
