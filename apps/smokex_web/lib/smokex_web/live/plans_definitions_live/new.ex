defmodule SmokexWeb.PlansDefinitionsLive.New do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias Smokex.PlanDefinition

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
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
        %Socket{} = socket
      ) do
    case PlanDefinitions.create(plan_definition_attrs) do
      {:ok, plan_definition} ->
        redirect_path =
          Routes.live_path(socket, SmokexWeb.PlansDefinitionsLive.Show, plan_definition.id)

        # TODO investigate about the stop response
        # Check https://github.com/chrismccord/phoenix_live_view_example/blob/master/lib/demo_web/live/user_live/edit.ex#L35
        {:noreply, redirect(socket, to: redirect_path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
