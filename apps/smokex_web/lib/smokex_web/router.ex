defmodule SmokexWeb.Router do
  use SmokexWeb, :router

  use Pow.Phoenix.Router
  use Sentry.PlugCapture
  use Pow.Extension.Phoenix.Router, extensions: [PowResetPassword, PowEmailConfirmation]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SmokexWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :basic_auth do
    plug(SmokexWeb.Plugs.BasicAuth)
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :skip_csrf_protection do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:put_secure_browser_headers)
  end

  pipeline :stripe_webhooks do
    plug SmokexWeb.Payments.Stripe.Webhooks.Plug
  end

  pipeline :pow_email_layout do
    plug :put_pow_mailer_layout, {SmokexWeb.LayoutView, :email}
  end

  scope "/" do
    pipe_through [:browser, :pow_email_layout]

    pow_routes()
    pow_extension_routes()
  end

  scope "/", SmokexWeb do
    pipe_through([:skip_csrf_protection, :api])

    scope "/auth" do
      get "/slack/callback", Callbacks.Slack, :callback
    end

    scope "/payments/stripe" do
      pipe_through(:stripe_webhooks)

      post("/webhooks", Payments.Stripe.Webhooks, :handle_webhook)
    end
  end

  scope "/", SmokexWeb do
    pipe_through :browser

    get "/sitemap.xml", Controllers.Sitemap, :build

    get "/", Controllers.Landing, :show
    get "/landing", Controllers.Landing, :show
    get "/privacy-policy", Controllers.Legal, :privacy_policy
    get "/terms-and-conditions", Controllers.Legal, :terms_and_conditions

    live "/pricing", PricingLive.Show
    live "/docs", DocumentationLive.Show
    live "/getting-started", WelcomeLive.Show

    scope "/" do
      pipe_through :protected

      live "/stats", StatsLive.Show

      scope "/my-account", MyAccountLive do
        live "/", Show
        live "/edit", Edit
        live "/billing", Billing
        live "/integrations/slack", Integrations.Slack
        live "/secrets", Administration.Secrets.Show
        live "/secrets/new", Administration.Secrets.New
        live "/secrets/:id/edit", Administration.Secrets.Edit
      end

      live "/plans", PlansDefinitionsLive.List
      live "/plans/new", PlansDefinitionsLive.New
      live "/plans/:id", PlansDefinitionsLive.Show
      live "/plans/:id/edit", PlansDefinitionsLive.Edit

      live "/executions", PlansExecutionsLive.List
      live "/executions/:id", PlansExecutionsLive.Show

      scope "/payments" do
        get "/success", Payments.Stripe.Callbacks, :success
        get "/cancel", Payments.Stripe.Callbacks, :cancel
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", SmokexWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  import Phoenix.LiveDashboard.Router

  scope "/" do
    pipe_through :browser
    pipe_through :basic_auth
    live_dashboard "/boat/dog/dashboard", metrics: SmokexWeb.Telemetry
  end

  #
  # Plug function needed to add the base layout to pow emails, for more info
  # see: https://hexdocs.pm/pow/Pow.Phoenix.Mailer.Mail.html#content
  #
  defp put_pow_mailer_layout(conn, layout), do: put_private(conn, :pow_mailer_layout, layout)
end
