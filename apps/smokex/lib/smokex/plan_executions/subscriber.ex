defmodule Smokex.PlanExecutions.Subscriber do
  @moduledoc """
  Context module to handle plan executions.
  """

  alias Smokex.PlanExecution

  @doc """
  Subscribes to the plan execution.
  """
  @spec subscribe(PlanExecution.t()) :: :ok | {:error, term}
  def subscribe(%PlanExecution{} = plan_execution) do
    Phoenix.PubSub.subscribe(Smokex.PubSub, "#{plan_execution.id}", link: true)
  end

  @spec subscribe(String.t()) :: :ok | {:error, term}
  def subscribe(plan_execution_id) when is_binary(plan_execution_id) do
    Phoenix.PubSub.subscribe(Smokex.PubSub, plan_execution_id, link: true)
  end

  @doc """
  Subscribes to the plan execution.
  """
  @spec subscribe(list(PlanExecution.t())) :: :ok | {:error, term}
  def subscribe([]), do: :ok

  def subscribe([%PlanExecution{} | _] = plan_executions) when is_list(plan_executions) do
    Enum.each(plan_executions, &subscribe/1)
  end

  @spec notify_change(term, PlanExecution.status()) :: term
  def notify_change(result, event) do
    with {:ok, plan_execution} <- result do
      Phoenix.PubSub.broadcast(
        Smokex.PubSub,
        "#{plan_execution.id}",
        {event, plan_execution}
      )
    end

    result
  end
end
