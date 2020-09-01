defmodule Smokex.Repo.Migrations.CreatePlansDefinitionsOrganizations do
  use Ecto.Migration

  def change do
    create table(:plans_definitions_organizations) do
      add(:plan_definition_id, references(:plans_definitions), null: false)
      add(:organization_id, references(:organizations), null: false)

      timestamps()
    end
  end
end
