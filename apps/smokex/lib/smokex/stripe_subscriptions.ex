defmodule Smokex.StripeSubscriptions do
  require Logger

  alias Smokex.Subscriptions.StripeSubscription
  alias Smokex.Users.User
  alias Smokex.Organizations
  alias Smokex.Organizations.Organization

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
  Returns true or false depending if the organization of the user has a
  subscription.

  TODO the template calling this function should check if the user has
  permissions to manage billing
  """
  @spec has_subscription?(User.t() | nil) :: boolean
  def has_subscription?(%User{} = user) do
    with {:ok, %Organization{id: organization_id}} <- Organizations.get_organization(user),
         %StripeSubscription{} <-
           Smokex.Repo.get_by(StripeSubscription, organization_id: organization_id) do
      true
    else
      _ -> false
    end
  end

  def has_subscription?(nil), do: false

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
  Creates a new entry in the `stripe_subscriptions` table between the
  organization and the given Stripe customer.

  This does not mean the organization has an active subscription yet, but it
  creates the information to activate the organization's subscription when the
  Stripe webhooks arrives in the system.
  """
  @spec create_customer(organization :: Organization.t(), customer_id :: String.t()) ::
          {:ok, Organization.t()} | {:error, Ecto.Changeset.t()}
  def create_customer(%Organization{} = organization, customer_id) when is_binary(customer_id) do
    %StripeSubscription{}
    |> StripeSubscription.create_changeset(%{
      organization: organization,
      customer_id: customer_id
    })
    |> Smokex.Repo.insert()
  end

  @doc """
  Creates a Stripe subscription with the `subscription_id` for the given
  customer.

  *It is important to know* This function creates the subscription entry with
  no `organization_id` information and it is necessary to receive additional
  webhooks to match the subscription created here with the customer's
  organization.
  """
  @spec create_subscription(
          customer_id :: integer,
          subscription_id :: String.t()
        ) ::
          {:ok, StripeSubscription.t()} | {:error, Ecto.Changeset.t()}
  def create_subscription(customer_id, subscription_id)
      when is_binary(subscription_id) and is_binary(customer_id) do
    with %StripeSubscription{customer_id: ^customer_id, subscription_id: nil} = subscription <-
           __MODULE__.with_customer_id_only(customer_id) do
      __MODULE__.update_subscription(subscription, subscription_id)
    else
      nil ->
        %StripeSubscription{}
        |> StripeSubscription.create_changeset(%{
          organization_id: nil,
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
  Cancels an active subscription for the organization.

  If the organization has multiple active subscriptions, an error will be
  returned an manual intervention will be needed.
  """
  @spec cancel_subscription(Organization.t()) :: {:ok, :deleted} | {:error, term}
  def cancel_subscription(%Organization{id: organization_id}) do
    with %StripeSubscription{customer_id: customer_id} = subscription_reference <-
           __MODULE__.get_by(organization_id: organization_id),
         {:ok, %Stripe.List{data: [%Stripe.Subscription{id: subscription_id}]}} <-
           Stripe.Subscription.list(%{customer: customer_id, status: "active"}),
         {:ok, _subscription} <- Stripe.Subscription.delete(subscription_id),
         {:ok, _subscription_reference} <- Smokex.Repo.delete(subscription_reference) do
      {:ok, :deleted}
    else
      {:ok, %Stripe.List{data: subscriptions}} ->
        Logger.error("Multiple subscriptions active: #{inspect(subscriptions)}")
        {:error, :multiple_subscriptions}

      nil ->
        Logger.error("Cannot cancel subscription, organization not found: #{organization_id}")
        {:error, "organization_not_found"}

      {:error, _reason} = error ->
        Logger.error("Cannot cancel subscription: #{inspect(error)}")
        error

      error ->
        Logger.error("Cannot cancel subscription: #{inspect(error)}")
        {:error, inspect(error)}
    end
  end

  @doc """
  Returns the Stripe price that should be used by the clients.
  """
  @spec get_price() :: String.t()
  def get_price() do
    Application.get_env(:smokex, :stripe_price_id)
  end
end
