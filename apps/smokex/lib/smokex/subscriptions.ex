defmodule Smokex.StripeSubscriptions do
  alias Smokex.Users.User

  alias Smokex.Subscriptions.StripeSubscription
  alias Smokex.Users.User

  @doc """
  Gets a subscription by the `customer id`.

  If no subscription is found, raises an error.
  """
  @spec get_by(keyword) :: StripeSubscription.t()
  def get_by(params) do
    Smokex.Repo.get_by!(StripeSubscription, params)
  end

  @doc """
  Creates a new user entry in the `stripe_subscriptions` table with the customer info.

  This does not mean the user has an active subscription yet, but it creates
  the information to track the user information is Stripe.
  """
  @spec create_customer(user :: User.t(), customer_id :: String.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_customer(%User{} = user, customer_id) when is_binary(customer_id) do
    %StripeSubscription{}
    |> StripeSubscription.create_changeset(%{
      user: user,
      customer_id: customer_id
    })
    |> Smokex.Repo.insert()
  end

  @doc """
  Updates a Stripe subscription with the `subscription_id`.
  """
  @spec update_subscription(user :: User.t(), customer_id :: String.t()) ::
          {:ok, StripeSubscription.t()} | {:error, Ecto.Changeset.t()}
  def update_subscription(%StripeSubscription{} = user, subscription_id)
      when is_binary(subscription_id) do
    %StripeSubscription{}
    |> StripeSubscription.update_changeset(%{
      subscription_id: subscription_id
    })
    |> Smokex.Repo.insert()
  end
end
