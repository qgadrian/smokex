defmodule SmokexWeb.PlansDefinitionsLive.New do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.Limits
  alias Smokex.PlanDefinitions
  alias Smokex.PlanDefinition

  @impl true
  def mount(_params, session, socket) do
    default_plan_definition_value = """
    # get a session token
    - post:
        host: "#{Routes.test_endpoint_url(socket, :login)}"
        headers:
          content-type: "application/json"
        body:
          user: "smokex"
          password: "may the force be with you"
        save_from_response:
          - variable_name: "session_token"
            json_path: "session_token"

    # request a list of elements (will timeout after 4 seconds)
    - get:
        host: "#{Routes.test_endpoint_url(socket, :get_players)}"
        headers:
          auth: ${session_token}
        options:
          timeout: 4000
        expect:
          json:
            players:
              - name: "Michael"
                last_name: "Jordan"
                number: 23
              - name: "LeBron"
                last_name: "James"
                number: 23
              - name: "Kobe"
                last_name: "Bryant"
                number: 24
        save_from_response:
          - variable_name: "jordan"
            json_path: "players[0].number"
          - variable_name: "james"
            json_path: "players[1].number"
          - variable_name: "kobe"
            json_path: "players[2].number"

    # send a request with query params
    - get:
        host: "#{Routes.test_endpoint_url(socket, :best_laker, "lakers")}"
        headers:
          auth: ${session_token}
        query:
          number: ${kobe}
        expect:
          json:
            best_laker: true

    # put some data in a server
    - put:
        host: "#{Routes.test_endpoint_url(socket, :message)}"
        headers:
          auth: ${session_token}
        query:
          number: ${kobe}
          message: "mamba forever"
        expect:
          json:
            response: "your message was sent to player 24"
    """

    socket =
      socket
      |> SessionHelper.assign_user!(session)
      |> check_permission()
      |> assign(
        changeset: Ecto.Changeset.change(%PlanDefinition{content: default_plan_definition_value})
      )
      |> assign(:default_content, default_plan_definition_value)
      |> assign(page_title: "Create test plan")

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"plan_definition" => plan_definition_attrs}, %Socket{} = socket) do
    plan_definition =
      %PlanDefinition{}
      |> PlanDefinition.create_changeset(plan_definition_attrs)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: plan_definition)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "save",
        %{"plan_definition" => plan_definition_attrs},
        %Socket{assigns: %{current_user: user}} = socket
      ) do
    case PlanDefinitions.create(user, plan_definition_attrs) do
      {:ok, plan_definition} ->
        redirect_path =
          Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.List, plan: plan_definition.id)

        {:noreply, push_redirect(socket, to: redirect_path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  #
  # Private functions
  #

  @spec check_permission(Socket.t()) :: Socket.t()
  defp check_permission(%Socket{assigns: %{current_user: user}} = socket) do
    if Limits.can_create_plan_definition?(user) do
      socket
    else
      redirect_path = Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.List)

      push_redirect(socket, to: redirect_path)
    end
  end
end
