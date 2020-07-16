defmodule SmokexWeb.Router do
  use SmokexWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SmokexWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SmokexWeb do
    pipe_through :browser

    get "/landing", Controllers.Landing, :show
    get "/pricing", Controllers.Pricing, :show

    live "/", StatusLive.Show
    live "/stats", StatusLive.Show

    live "/plans", PlansDefinitionsLive.List
    live "/plans/new", PlansDefinitionsLive.New
    live "/plans/:id", PlansDefinitionsLive.Show
    live "/plans/:id/edit", PlansDefinitionsLive.Edit
    live "/plans/:plan_definition_id/executions", PlansExecutionsLive.List

    live "/executions", PlansExecutionsLive.All
    live "/executions/:status/page/:page", PlansExecutionsLive.All
    live "/executions/:id", PlansExecutionsLive.Show
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
