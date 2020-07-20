defmodule SmokexWeb.Payments.Stripe.Webhooks do
  require Logger

  use SmokexWeb, :controller

  alias Smokex.Repo
  alias Smokex.Users.User
  alias Smokex.Users

  @epoch_year_2069 3_138_032_874

  @spec handle_webhook(Plug.Conn.t(), map) :: Plug.Conn.t()
  def handle_webhook(%Plug.Conn{assigns: %{stripe_event: stripe_event}} = conn, _params) do
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
  # Handles a new Stripe customer created by updating the `stripe_customer_id`
  # field in the users table.
  #
  defp handle_event(
         conn,
         %{
           type: "customer.created",
           data: %{
             object: %Stripe.Customer{
               email: email,
               id: stripe_id
             }
           }
         } = stripe_event
       ) do
    Logger.info("Stripe event `customer_created`: #{inspect(stripe_event)}")

    with user when not is_nil(user) <- Repo.get_by(User, email: email),
         {:ok, user} <- Users.update(user, %{stripe_customer_id: stripe_id}) do
      Logger.info("Updated user stripe_id: #{user.id}")

      SmokexWeb.SessionHelper.sync_user(conn, user)

      {:ok, :success}
    else
      error ->
        Logger.error("Error processing customer created: #{inspect(error)}")
        {:error, error}
    end
  end

  #
  # Handles a new invoice paid by the user and updates the
  # `subscription_expires_at` in the user table to the end of the subscription
  # period.
  #
  # This will handle any new subscription or renewal.
  #
  # For more info, see:
  # https://stripe.com/docs/billing/subscriptions/webhooks#tracking
  #
  defp handle_event(
         conn,
         %{
           type: "invoice.paid",
           data: %{
             object: %Stripe.Invoice{
               customer: customer,
               lines: %Stripe.List{
                 data: [
                   %Stripe.LineItem{period: %{end: period_end_timestamp}}
                 ]
               }
             }
           }
         } = stripe_event
       ) do
    Logger.info("Stripe event `invoice_paid`: #{inspect(stripe_event)}")

    customer_id =
      case customer do
        %Stripe.Customer{id: id} -> id
        id when is_binary(id) -> id
      end

    with {:ok, subscription_expires_at} <- DateTime.from_unix(period_end_timestamp),
         user when not is_nil(user) <- Repo.get_by(User, stripe_customer_id: customer_id),
         {:ok, user} <- Users.update(user, %{subscription_expires_at: subscription_expires_at}) do
      {:ok, :success}
    else
      error ->
        Logger.error("Error processing invoice payment: #{inspect(error)}")
        {:error, error}
    end
  end

  # TODO handle subscriptions cancelled
  defp handle_event(_conn, %{type: event_type} = _event) do
    Logger.warn("Unknown Stripe event: #{event_type}")

    {:ok, :unsupported_event}
  end
end
