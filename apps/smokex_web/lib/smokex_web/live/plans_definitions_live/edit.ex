defmodule SmokexWeb.PlansDefinitionsLive.Edit do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias Smokex.PlanDefinition

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    socket =
      socket
      |> assign(id: id)
      |> fetch_plan_definition()
      |> put_page_title

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"plan_definition" => plan_definition_attrs}, %Socket{} = socket) do
    plan_definition =
      %PlanDefinition{}
      |> PlanDefinition.update_changeset(plan_definition_attrs)
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
          Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.List, plan: plan_definition.id)

        # TODO investigate about the stop response
        # Check https://github.com/chrismccord/phoenix_live_view_example/blob/master/lib/demo_web/live/user_live/edit.ex#L35
        {:noreply, push_redirect(socket, to: redirect_path)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  #
  # Private functions
  #

  defp fetch_plan_definition(%Socket{assigns: %{id: id, current_user: user}} = socket) do
    plan_definition = PlanDefinitions.get!(user, id)
    changeset = Ecto.Changeset.change(plan_definition)

    assign(socket, plan_definition: plan_definition, changeset: changeset)
  end

  defp put_page_title(%Socket{assigns: %{plan_definition: plan_definition}} = socket) do
    assign(socket, page_title: "Edit #{plan_definition.name}")
  end
end
