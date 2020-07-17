defmodule SmokexWeb.Router do
  use SmokexWeb, :router
  use Pow.Phoenix.Router

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

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser

    pow_routes()
  end

  scope "/", SmokexWeb do
    pipe_through :browser

    get "/landing", Controllers.Landing, :show
    get "/pricing", Controllers.Pricing, :show

    live "/", StatusLive.Show
    live "/stats", StatusLive.Show

    live "/plans/new", PlansDefinitionsLive.New
    live "/plans/:id", PlansDefinitionsLive.Show
    live "/plans/:id/edit", PlansDefinitionsLive.Edit

    live "/executions", PlansExecutionsLive.All
    live "/executions/:status/page/:page", PlansExecutionsLive.All
    live "/executions/:id", PlansExecutionsLive.Show

    scope "/" do
      pipe_through :protected

      live "/plans", PlansDefinitionsLive.List
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
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: SmokexWeb.Telemetry
    end
  end
end
