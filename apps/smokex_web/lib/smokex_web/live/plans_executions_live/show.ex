defmodule SmokexWeb.PlansExecutionsLive.Show do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanDefinitions
  alias Smokex.PlanExecutions
  alias Smokex.PlanExecution
  alias Smokex.Result
  alias SmokexWeb.PlanExecutions.Components.StatusBadge
  alias SmokexWeb.PlanExecutions.Components.Progress
  alias SmokexWeb.PlansExecutionsLive.Components.Show.Table, as: ResultsTable

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    socket =
      socket
      |> SessionHelper.assign_user!(session)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    if connected?(socket), do: PlanExecutions.subscribe(id)

    socket =
      socket
      |> assign(id: id)
      |> fetch_plan_execution()
      |> fetch_plan_definition
      |> assign(page_title: "Execution #{id}")

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:result, %Result{} = result}, %Socket{assigns: %{results: results}} = socket) do
    results = [result | results]

    {:noreply, assign(socket, results: results)}
  end

  @impl Phoenix.LiveView
  def handle_info({_event, %PlanExecution{} = plan_execution}, %Socket{} = socket) do
    {:noreply, assign(socket, plan_execution: plan_execution)}
  end

  def actions_length_label(results) do
    length(results)
    |> action_label
  end

  #
  # Private functions
  #

  @spec fetch_plan_execution(Socket.t()) :: Socket.t()
  defp fetch_plan_execution(%Socket{assigns: %{id: id, current_user: user}} = socket) do
    with plan_execution <- PlanExecutions.get!(user, id),
         plan_execution <- Smokex.Repo.preload(plan_execution, results: :response) do
      socket
      |> assign(plan_execution: plan_execution)
      |> assign(results: plan_execution.results)
    end
  end

  defp fetch_plan_definition(
         %Socket{assigns: %{plan_execution: plan_execution, current_user: user}} = socket
       ) do
    plan_definition = PlanDefinitions.get!(user, plan_execution.plan_definition_id)
    changeset = Ecto.Changeset.change(plan_definition)

    assign(socket, plan_definition: plan_definition, changeset: changeset)
  end

  defp action_label(results_length) do
    if results_length > 1 do
      "#{results_length} actions"
    else
      "#{results_length} action"
    end
  end
end
