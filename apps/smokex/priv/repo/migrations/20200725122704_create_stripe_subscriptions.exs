defmodule Smokex.Repo.Migrations.CreateStripeSubscriptions do
  use Ecto.Migration

  def change do
    create table(:stripe_subscriptions) do
      add(:user_id, references(:users), null: true)

      add(:customer_id, :string, null: false)
      add(:subscription_id, :string, null: true)

      timestamps()
    end
  end
end
