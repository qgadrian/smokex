defmodule Smokex.Repo.Migrations.CreateExecutionStepsResults do
  use Ecto.Migration

  def change do
    create table(:execution_steps_results) do
      add(:action, :string, null: false)
      add(:host, :string, null: true)
      add(:failed_assertions, {:array, :map}, null: false)
      add(:result, :string, null: false)
    end
  end
end
