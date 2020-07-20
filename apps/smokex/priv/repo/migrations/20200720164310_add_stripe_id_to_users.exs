defmodule Smokex.Repo.Migrations.AddStripeIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:stripe_customer_id, :string, null: true)
    end
  end
end
