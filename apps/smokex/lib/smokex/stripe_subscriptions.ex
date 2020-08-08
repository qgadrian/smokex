defmodule Smokex.StripeSubscriptions do
  require Logger

  alias Smokex.Subscriptions.StripeSubscription
  alias Smokex.Users.User
  alias Smokex.Users.User

  import Ecto.Query

  @doc """
  Gets a subscription by the `customer id`.

  If no subscription is found, returns `nil`.
  """
  @spec get_by(keyword) :: StripeSubscription.t()
  def get_by(params) do
    Smokex.Repo.get_by(StripeSubscription, params)
  end

  @doc """
  Gets a subscription by that only has the `customer id` field, and no
  `subscription_id`.

  If no subscription is found, returns `nil`.
  """
  @spec with_customer_id_only(customer_id :: String.t()) :: StripeSubscription.t()
  def with_customer_id_only(customer_id) when is_binary(customer_id) do
    query =
      from(subscription in StripeSubscription,
        where: subscription.customer_id == ^customer_id,
        where: is_nil(subscription.subscription_id)
      )

    Smokex.Repo.one(query)
  end

  @doc """
  Creates a new user entry in the `stripe_subscriptions` table with the
  customer info.

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
  Creates a Stripe subscription with the `subscription_id` for the given
  customer.
  """
  @spec create_or_update_subscription(
          user_id :: integer | nil,
          subscription_id :: String.t(),
          customer_id :: String.t()
        ) ::
          {:ok, StripeSubscription.t()} | {:error, Ecto.Changeset.t()}
  def create_or_update_subscription(user_id, customer_id, subscription_id)
      when is_binary(subscription_id) and is_binary(customer_id) do
    with %StripeSubscription{customer_id: ^customer_id, subscription_id: nil} = subscription <-
           __MODULE__.with_customer_id_only(customer_id) do
      __MODULE__.update_subscription(subscription, subscription_id)
    else
      nil ->
        %StripeSubscription{}
        |> StripeSubscription.create_changeset(%{
          user_id: user_id,
          customer_id: customer_id,
          subscription_id: subscription_id
        })
        |> Smokex.Repo.insert()
    end
  end

  @doc """
  Updates a Stripe subscription with the `subscription_id`.
  """
  @spec update_subscription(subscription :: StripeSubscription.t(), subscription_id :: String.t()) ::
          {:ok, StripeSubscription.t()} | {:error, Ecto.Changeset.t()}
  def update_subscription(%StripeSubscription{} = subscription, subscription_id)
      when is_binary(subscription_id) do
    subscription
    |> StripeSubscription.update_changeset(%{
      subscription_id: subscription_id
    })
    |> Smokex.Repo.update()
  end

  @doc """
  Cancels an active subscription for the user.

  If the user has multiple active subscriptions, an error will be returned an
  manual intervention will be needed.
  """
  @spec cancel_subscription(User.t()) :: {:ok, :deleted} | {:error, term}
  def cancel_subscription(%User{} = user) do
    with {:ok, %StripeSubscription{customer_id: customer_id}} <- __MODULE__.get_by(user: user),
         {:ok, %Stripe.List{data: [%Stripe.Subscription{id: subscription_id}]}} <-
           Stripe.Subscription.list(customer: customer_id, status: "active"),
         {:ok, _subscription} <- Stripe.Subscription.delete(subscription_id) do
      {:ok, :deleted}
    else
      {:ok, %Stripe.List{data: subscriptions}} ->
        Logger.error("Multiple subscriptions active: #{inspect(subscriptions)}")
        {:error, :multiple_subscriptions}

      nil ->
        {:error, "user_not_found"}

      {:error, _reason} = error ->
        error

      error ->
        {:error, inspect(error)}
    end
  end
end
