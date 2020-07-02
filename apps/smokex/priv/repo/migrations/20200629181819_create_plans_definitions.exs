defmodule Smokex.Repo.Migrations.CreatePlansDefinitions do
  use Ecto.Migration

  def change do
    create table(:plans_definitions) do
      add(:name, :string, null: false)

      timestamps()
    end
  end
end
