defmodule SmokexWeb.PlansExecutionsLive.Show do
  use SmokexWeb, :live_view

  alias Phoenix.LiveView.Socket
  alias Smokex.PlanExecutions
  alias Smokex.PlanExecution
  alias Smokex.Result
  alias SmokexWeb.PlanExecutions.Components.StatusBadge
  alias SmokexWeb.PlanExecutions.Components.Progress
  alias SmokexWeb.PlansExecutionsLive.Components.Result.Table, as: ResultsTable

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    if connected?(socket), do: PlanExecutions.subscribe(id)

    socket =
      socket
      |> assign(id: id)
      |> fetch_plan_execution()
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

  #
  # Private functions
  #

  @spec fetch_plan_execution(Socket.t()) :: Socket.t()
  defp fetch_plan_execution(%Socket{assigns: %{id: id}} = socket) do
    with plan_execution <- PlanExecutions.get!(id),
         plan_execution <- Smokex.Repo.preload(plan_execution, :results) do
      socket
      |> assign(plan_execution: plan_execution)
      |> assign(results: plan_execution.results)
    end
  end
end
