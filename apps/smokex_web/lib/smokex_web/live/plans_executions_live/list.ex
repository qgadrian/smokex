defmodule SmokexWeb.PlansExecutionsLive.List do
  use SmokexWeb, :live_view

  require Logger

  alias Smokex.PlanExecutions.Subscriber, as: PlanExecutionsSubscriber
  alias Smokex.PlanDefinitions.Scheduler, as: PlanDefinitionScheduler
  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias Smokex.PlanExecution
  alias Smokex.PlanExecutions
  alias SmokexWeb.PlansExecutionsLive.Components.Sidebar
  alias SmokexWeb.PlansExecutionsLive.Components.Table, as: TableComponent
  alias SmokexWeb.PlansExecutionsLive.Components.GetStarted, as: GetStarted

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(page_title: "Executions")
      |> SessionHelper.assign_user!(session)

    {:ok, socket, temporary_assigns: [plan_executions: []]}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    status =
      params
      |> Map.get("status", "all")
      |> String.to_existing_atom()

    plan_definition_id =
      params
      |> Map.get("plan", "")
      |> Integer.parse()
      |> case do
        {plan_definition_id, ""} -> plan_definition_id
        :error -> nil
      end

    socket =
      socket
      |> assign(page: 1)
      |> assign(active_filter: status)
      |> assign(plan_definition_id: plan_definition_id)
      |> subscribe_to_changes()
      |> fetch_executions
      |> fetch_plan_definitions
      |> fetch_plan_definition
      |> set_total_results_count

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("load-more", _, %Socket{assigns: %{page: page}} = socket) do
    socket =
      socket
      |> assign(page: page + 1)
      |> fetch_executions()

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "filter_update",
        %{"filter" => %{"plan_definition_id" => plan_definition_id}},
        %Socket{assigns: %{active_filter: status_filter}} = socket
      ) do
    plan_definition_id =
      case Integer.parse(plan_definition_id) do
        {plan_definition_id, ""} -> plan_definition_id
        :error -> nil
      end

    socket =
      socket
      |> assign(plan_definition_id: plan_definition_id)
      |> fetch_executions

    path_to =
      case plan_definition_id do
        nil ->
          Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.List, status: status_filter)

        plan_definition_id ->
          Routes.live_path(
            socket,
            SmokexWeb.PlansExecutionsLive.List,
            status: status_filter,
            plan: plan_definition_id
          )
      end

    {:noreply, push_patch(socket, to: path_to)}
  end

  @impl Phoenix.LiveView
  def handle_event(
        "execute",
        _params,
        %Socket{assigns: %{current_user: user, plan_definition: plan_definition}} = socket
      ) do
    with {:ok, plan_execution_id} <- PlanDefinitionScheduler.enqueue_job(plan_definition, user) do
      redirect_path =
        Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.Show, plan_execution_id)

      {:noreply, push_redirect(socket, to: redirect_path)}
    else
      error ->
        # TODO handle error and show feedback to user
        Logger.error(inspect(error))
        {:noreply, socket}
    end
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:created, %PlanExecution{}},
        %Socket{assigns: %{active_filter: :all}} = socket
      ) do
    socket =
      socket
      |> fetch_executions()
      |> subscribe_to_changes()

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {:created, %PlanExecution{status: status}},
        %Socket{assigns: %{active_filter: status}} = socket
      ) do
    socket =
      socket
      |> fetch_executions()
      |> subscribe_to_changes()

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(
        {_event, %PlanExecution{id: plan_execution_id} = plan_execution},
        %Socket{assigns: %{plan_executions: plan_executions}} = socket
      ) do
    updated_plan_executions =
      Enum.map(plan_executions, fn
        %PlanExecution{id: ^plan_execution_id} -> plan_execution
        other_plan_execution -> other_plan_execution
      end)

    socket = assign(socket, plan_executions: updated_plan_executions)

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:result, _result}, %Socket{} = socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info(message, socket) do
    Logger.warn("Received unhandled message #{inspect(message)}")

    {:noreply, socket}
  end

  #
  # Private functions
  #

  @spec fetch_plan_definition(Socket.t()) :: Socket.t()
  defp fetch_plan_definition(%Socket{assigns: %{current_user: nil}} = socket), do: socket

  defp fetch_plan_definition(%Socket{assigns: %{plan_definition_id: nil}} = socket) do
    assign(socket, plan_definition: nil)
  end

  defp fetch_plan_definition(
         %Socket{assigns: %{plan_definition_id: id, current_user: user}} = socket
       ) do
    plan_definition = PlanDefinitions.get!(user, id)
    changeset = Ecto.Changeset.change(plan_definition)

    assign(socket, plan_definition: plan_definition, changeset: changeset)
  end

  @spec fetch_plan_definitions(Socket.t()) :: Socket.t()
  defp fetch_plan_definitions(%Socket{assigns: %{current_user: user}} = socket) do
    plan_definitions = PlanDefinitions.all(user)

    assign(socket, plan_definitions: plan_definitions)
  end

  @spec fetch_executions(Socket.t()) :: Socket.t()
  defp fetch_executions(
         %Socket{
           assigns: %{
             current_user: user,
             active_filter: status,
             page: page,
             plan_definition_id: plan_definition_id
           }
         } = socket
       ) do
    more_plans_executions =
      user
      |> PlanExecutions.all(page, status: status, plan_definition_id: plan_definition_id)
      |> Smokex.Repo.preload(:plan_definition)
      |> subscribe_to_changes()

    assign(socket, plan_executions: more_plans_executions)
  end

  @spec set_total_results_count(Socket.t()) :: Socket.t()
  defp set_total_results_count(
         %Socket{
           assigns: %{
             current_user: user,
             active_filter: status,
             plan_definition_id: plan_definition_id
           }
         } = socket
       ) do
    executions_count =
      PlanExecutions.count_total(user, status: status, plan_definition_id: plan_definition_id)

    assign(socket, executions_count: executions_count)
  end

  @spec subscribe_to_changes(list(PlanExecution.t())) :: list(PlanExecution.t())
  defp subscribe_to_changes(plan_executions) when is_list(plan_executions) do
    Smokex.PlanExecutions.subscribe(plan_executions)
    plan_executions
  end

  @spec subscribe_to_changes(Socket.t()) :: list(PlanExecution.t())
  defp subscribe_to_changes(%Socket{assigns: %{plan_executions: plan_executions}} = socket)
       when is_list(plan_executions) do
    Smokex.PlanExecutions.subscribe(plan_executions)
    socket
  end

  @spec subscribe_to_changes(Socket.t()) :: Socket.t()
  defp subscribe_to_changes(%Socket{assigns: %{plan_definition_id: plan_definition_id}} = socket)
       when is_number(plan_definition_id) do
    PlanDefinitions.subscribe("#{plan_definition_id}")

    socket
  end

  # TODO this will subscribe to all as a fallback. But this does not mean that
  # with an active filter, for example `finished` the process will be
  # subscribed (will not) and receive update messages
  defp subscribe_to_changes(%Socket{} = socket) do
    PlanExecutionsSubscriber.subscribe_to_any()

    socket
  end
end
