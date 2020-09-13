defmodule SmokexWeb.PlansDefinitionsLive.New do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.Limits
  alias Smokex.PlanDefinitions
  alias Smokex.PlanDefinition

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session)
      |> check_permission()
      |> assign(changeset: Ecto.Changeset.change(%PlanDefinition{}))
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
          Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.All, plan: plan_definition.id)

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
      redirect_path = Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.All)

      push_redirect(socket, to: redirect_path)
    end
  end
end
