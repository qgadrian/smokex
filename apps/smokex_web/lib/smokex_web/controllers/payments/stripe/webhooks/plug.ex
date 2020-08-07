defmodule SmokexWeb.Payments.Stripe.Webhooks.Plug do
  @behaviour Plug

  require Logger

  import Plug.Conn

  def init(config), do: config

  def call(%{request_path: "/payments/stripe/webhooks"} = conn, _) do
    Logger.info("Stripe webhook received")

    signing_secret = Application.get_env(:stripity_stripe, :signing_secret)
    [stripe_signature] = Plug.Conn.get_req_header(conn, "stripe-signature")

    with {:ok, body} <- SmokexWeb.CacheBodyReader.read_cached_body(conn),
         {:ok, stripe_event} <-
           Stripe.Webhook.construct_event(body, stripe_signature, signing_secret) do
      Logger.info("Stripe webhook parsed", metadata: [stripe_event: stripe_event])

      Plug.Conn.assign(conn, :stripe_event, stripe_event)
    else
      {:error, error} ->
        Logger.error("Error processing webhook request: #{inspect(error)}")

        conn
        |> send_resp(:bad_request, "error")
        |> halt()
    end
  end

  def call(conn, _), do: conn
end
