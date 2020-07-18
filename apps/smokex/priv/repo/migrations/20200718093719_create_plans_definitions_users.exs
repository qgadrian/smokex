defmodule Smokex.Repo.Migrations.CreatePlansDefinitionsUsers do
  use Ecto.Migration

  def change do
    create table(:plans_definitions_users) do
      add(:plan_definition_id, references(:plans_definitions), null: false)
      add(:user_id, references(:users), null: false)
    end
  end
end
