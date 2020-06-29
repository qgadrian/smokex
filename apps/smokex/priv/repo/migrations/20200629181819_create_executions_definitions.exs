defmodule Smokex.Repo.Migrations.CreateExecutionsDefinitions do
  use Ecto.Migration

  def change do
    create table(:execution_definitions) do
      add(:name, :string, null: false)

      timestamps()
    end
  end
end
