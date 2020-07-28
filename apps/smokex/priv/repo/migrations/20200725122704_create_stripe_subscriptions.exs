defmodule Smokex.Repo.Migrations.CreateStripeSubscriptions do
  use Ecto.Migration

  def change do
    create table(:stripe_subscriptions) do
      add(:user_id, references(:users), null: false)

      add(:customer_id, :string, null: false)
      add(:subscription_id, :string, null: true)
    end
  end
end
