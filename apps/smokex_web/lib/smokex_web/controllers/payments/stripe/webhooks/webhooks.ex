defmodule SmokexWeb.Payments.Stripe.Webhooks do
  @moduledoc """
  Module than handles webhooks from Stripe.

  A Stripe customer is linked to a organization in the database by having the
  value of the `organization_id` in the Stripe's customer field `customer_id`.
  """
  require Logger

  use SmokexWeb, :controller

  alias Smokex.Repo
  alias Smokex.Users.User
  alias Smokex.Users
  alias SmokexWeb.Tracer
  alias Smokex.Users.User
  alias Smokex.Organizations
  alias Smokex.Organizations.Organization
  alias Smokex.StripeSubscriptions, as: Subscriptions
  alias Smokex.Subscriptions.StripeSubscription

  @spec handle_webhook(Plug.Conn.t(), map) :: Plug.Conn.t()
  def handle_webhook(%Plug.Conn{assigns: %{stripe_event: stripe_event}} = conn, _params) do
    Tracer.trace_stripe_event(stripe_event)

    Logger.info("Stripe event: #{inspect(stripe_event)}")

    case handle_event(conn, stripe_event) do
      {:ok, _} -> handle_success(conn)
      {:error, error} -> handle_error(conn, error)
    end
  end

  @spec handle_success(Plug.Conn.t()) :: Plug.Conn.t()
  defp handle_success(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok")
  end

  @spec handle_error(Plug.Conn.t(), term) :: Plug.Conn.t()
  defp handle_error(conn, error) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(422, inspect(error))
  end

  #
  # Handles a new Stripe subscription created by updating the `subscription_id`
  # field in the stripe_subscriptions table.
  #
  defp handle_event(
         conn,
         %{
           type: "customer.created",
           data: %{
             object: %Stripe.Customer{
               email: email,
               id: customer_id
             }
           }
         }
       ) do
    with %User{} = user <- Repo.get_by(User, email: email),
         {:ok, %Organization{id: organization_id} = organization} <-
           Organizations.get_organization(user),
         {:ok, %StripeSubscription{customer_id: ^customer_id, organization_id: ^organization_id}} <-
           Subscriptions.create_customer(organization, customer_id) do
      Tracer.trace_user(user)
      Tracer.trace_stripe_customer(customer_id)

      Logger.info("Created stripe customer")

      SmokexWeb.SessionHelper.sync_user(conn, user)

      {:ok, :success}
    else
      {:error, reason} ->
        Logger.error("Error processing customer created: #{inspect(reason)}")
        {:error, reason}
    end
  end

  #
  # Handles a new invoice paid by the `organization` and updates the
  # `subscription_expires_at` in the `organizations` table to the end of the
  # subscription period.
  #
  # This will handle any new subscription or renewal.
  #
  # For more info, see:
  # https://stripe.com/docs/billing/subscriptions/webhooks#tracking
  #
  defp handle_event(
         _conn,
         %{
           type: "invoice.paid",
           data: %{
             object: %Stripe.Invoice{
               customer: customer,
               subscription: subscription,
               lines: %Stripe.List{
                 data: [
                   %Stripe.LineItem{period: %{end: period_end_timestamp}}
                 ]
               }
             }
           }
         }
       ) do
    customer_id =
      case customer do
        %Stripe.Customer{id: id} -> id
        id when is_binary(id) -> id
      end

    subscription_id =
      case subscription do
        %Stripe.Subscription{id: id} -> id
        id when is_binary(id) -> id
      end

    Tracer.trace_stripe_customer(customer_id)
    Tracer.trace_stripe_subscription(subscription_id)

    with {:ok, subscription_expires_at} <- DateTime.from_unix(period_end_timestamp),
         %StripeSubscription{customer_id: ^customer_id, subscription_id: ^subscription_id} =
           subscription <-
           Subscriptions.get_by(customer_id: customer_id, subscription_id: subscription_id),
         %StripeSubscription{organization: %Organization{} = organization} <-
           Repo.preload(subscription, :organization),
         {:ok, %Organization{} = organization} <-
           Organizations.update(organization, %{subscription_expires_at: subscription_expires_at}) do
      Tracer.trace_organization(organization)

      Logger.info("Updated subscription_expires_at to organization #{organization.id}")

      {:ok, :success}
    else
      %StripeSubscription{organization: nil} ->
        Logger.info("Subscription not found for customer: #{customer_id}")

        create_subscription(customer_id, subscription_id)

      {:error, reason} ->
        Logger.error("Error processing invoice payment: #{inspect(reason)}")
        {:error, reason}
    end
  end

  #
  # Handles a new subscription created for the organization and updates the
  # `stripe_subscriptions` table with the subscription id.
  #
  # For more info, see:
  # https://stripe.com/docs/api/subscriptions/create
  #
  # TODO handle each of the subscriptions, what will happen with organization's
  # with subscriptions cancelled in the past and then creates a new one?
  #
  defp handle_event(
         _conn,
         %{
           type: "customer.subscription.created",
           data: %{
             object: %Stripe.Subscription{
               customer: customer,
               id: subscription_id
             }
           }
         }
       ) do
    customer_id =
      case customer do
        %Stripe.Customer{id: id} -> id
        id when is_binary(id) -> id
      end

    Tracer.trace_stripe_customer(customer_id)
    Tracer.trace_stripe_subscription(subscription_id)

    with %StripeSubscription{customer_id: ^customer_id, subscription_id: nil} = subscription <-
           Subscriptions.with_customer_id_only(customer_id),
         {:ok, %StripeSubscription{subscription_id: ^subscription_id}} <-
           Subscriptions.update_subscription(subscription, subscription_id) do
      Logger.info("Updated subscription #{subscription_id} for customer #{customer_id}")

      {:ok, :success}
    else
      nil ->
        Logger.info("Subscription not found for customer: #{customer_id}")

        create_subscription(customer_id, subscription_id)

      {:error, reason} ->
        Logger.error("Error processing subscription creation: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # TODO handle subscriptions cancelled
  defp handle_event(_conn, _event) do
    Logger.warn("Unknown Stripe event")

    {:ok, :unsupported_event}
  end

  #
  # Fallback function used to create a Stripe subscription entry when no
  # information is present in the database.
  #
  defp create_subscription(customer_id, subscription_id) do
    Logger.info("Creating subscription #{subscription_id} for customer_id #{customer_id}")

    with {:ok, %StripeSubscription{subscription_id: ^subscription_id}} <-
           Subscriptions.create_subscription(customer_id, subscription_id) do
      Logger.info("Created subscription")

      {:ok, :success}
    else
      {:error, changeset} ->
        Logger.error("Error creating subscription: #{inspect(changeset)}")
        {:error, "error creating subscription"}
    end
  end
end
