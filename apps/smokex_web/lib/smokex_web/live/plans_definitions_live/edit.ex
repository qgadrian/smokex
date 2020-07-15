defmodule SmokexWeb.PlansDefinitionsLive.Edit do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias Smokex.PlanDefinition

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    socket =
      socket
      |> assign(id: id)
      |> fetch_plan_definition()

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"plan_definition" => plan_definition_attrs}, %Socket{} = socket) do
    plan_definition =
      %PlanDefinition{}
      |> PlanDefinition.changeset(plan_definition_attrs)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: plan_definition)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "save",
        %{"plan_definition" => plan_definition_attrs},
        %Socket{assigns: %{plan_definition: plan_definition}} = socket
      ) do
    case PlanDefinitions.update(plan_definition, plan_definition_attrs) do
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

  defp fetch_plan_definition(%Socket{assigns: %{id: id}} = socket) do
    plan_definition = PlanDefinitions.get(id)
    changeset = Ecto.Changeset.change(plan_definition)

    assign(socket, plan_definition: plan_definition, changeset: changeset)
  end
end
