defmodule SmokexWeb.PlansDefinitionsLive.Show do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias Smokex.PlanExecutions
  alias Smokex.PlanExecution

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    if connected?(socket), do: PlanDefinitions.subscribe(id)

    socket =
      socket
      |> assign(id: id)
      |> fetch_plan_definition()
      |> fetch_plan_executions()
      |> put_page_title()

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "execute",
        _params,
        %Socket{assigns: %{current_user: user, plan_definition: plan_definition}} = socket
      ) do
    {:ok, plan_execution} = PlanExecutions.create_plan_execution(user, plan_definition)
    Smokex.PlanExecutions.subscribe(plan_execution)

    with {:ok, %PlanExecution{id: id}} <- SmokexClient.Executor.execute(plan_execution) do
      redirect_path = Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.Show, id)

      {:noreply, redirect(socket, to: redirect_path)}
    else
      _ ->
        # TODO handle error
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:created, %PlanExecution{} = plan_execution},
        %Socket{assigns: %{plan_executions: plan_executions}} = socket
      ) do
    plan_executions = Enum.take([plan_execution | plan_executions], 5)
    {:noreply, assign(socket, plan_executions: plan_executions)}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {_event, %PlanExecution{id: id} = plan_execution},
        %Socket{assigns: %{plan_executions: plan_executions}} = socket
      ) do
    plan_executions =
      Enum.map(plan_executions, fn
        %PlanExecution{id: ^id} -> plan_execution
        plan_execution -> plan_execution
      end)

    {:noreply, assign(socket, plan_executions: plan_executions)}
  end

  @impl Phoenix.LiveView
  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  #
  # Private functions
  #

  defp fetch_plan_definition(%Socket{assigns: %{id: id, current_user: user}} = socket) do
    plan_definition = PlanDefinitions.get!(user, id)
    assign(socket, plan_definition: plan_definition)
  end

  defp fetch_plan_executions(%Socket{assigns: %{current_user: user, id: id}} = socket) do
    plan_executions = PlanExecutions.last_executions(user, plan_definition_id: id, limit: 5)
    assign(socket, plan_executions: plan_executions)
  end

  defp put_page_title(%Socket{assigns: %{plan_definition: plan_definition}} = socket) do
    assign(socket, page_title: plan_definition.name)
  end
end
