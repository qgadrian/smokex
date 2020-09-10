defmodule Smokex.Repo.Migrations.CreatePlansDefinitions do
  use Ecto.Migration

  def change do
    create table(:plans_definitions) do
      add(:name, :string, null: false)
      add(:description, :string, null: true)
      add(:cron_sentence, :string, null: true)
      add(:content, :text, null: false)

      timestamps()
    end
  end
end
