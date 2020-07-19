defmodule SmokexWeb.Payments.Stripe.Webhooks do
  require Logger

  use SmokexWeb, :controller

  alias Smokex.Repo
  alias Smokex.Users.User

  @epoch_year_2069 3_138_032_874

  def handle_webhook(%Plug.Conn{assigns: %{stripe_event: stripe_event}} = conn, _params) do
    case handle_event(conn, stripe_event) do
      {:ok, _} -> handle_success(conn)
      {:error, error} -> handle_error(conn, error)
    end
  end

  defp handle_success(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok")
  end

  defp handle_error(conn, error) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(422, inspect(error))
  end

  #
  # The checkout session event updates the subscription of the user.
  #
  # Since we have a date to handle the subscription, it will be set to year
  # 2069. This will reduce the number of changes in case the subscription
  # migrates to recurrent payments.
  #
  defp handle_event(
         conn,
         %{
           type: "customer.subscription.created",
           data: %{object: %Stripe.Session{client_reference_id: client_reference_id}}
         } = stripe_event
       ) do
    Logger.info("Received Stripe checkout event: #{inspect(stripe_event)}")

    with {client_reference_id, ""} <- Integer.parse(client_reference_id),
         user when not is_nil(user) <- Repo.get(User, client_reference_id),
         user <-
           Ecto.Changeset.change(user,
             subscription_expires_at: DateTime.from_unix!(@epoch_year_2069)
           ),
         {:ok, user} <- Repo.update(user) do
      Logger.info("Updated user subscription: #{user.id}")

      SmokexWeb.SessionHelper.sync_user(conn, user)

      {:ok, "success"}
    else
      error -> {:error, error}
    end
  end

  # TODO handle subscriptions cancelled and renewed

  defp handle_event(_conn, stripe_event) do
    Logger.error("Unknown Stripe event: #{inspect(stripe_event)}")

    {:error, :unsupported_event}
  end
end
