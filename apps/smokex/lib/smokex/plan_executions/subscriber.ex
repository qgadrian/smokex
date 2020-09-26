defmodule Smokex.PlanExecutions.Subscriber do
  @moduledoc """
  Context module to handle plan executions.
  """

  alias Smokex.PlanDefinition
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

  @doc """
  Notifies a new execution.

  This function broadcasts a message to the plan definition and organization
  topics.
  """
  @spec notify_created(PlanDefinition.t(), PlanExecution.t()) :: :ok | {:error, term()}
  def notify_created(
        %PlanDefinition{id: plan_definition_id, organization_id: organization_id},
        %PlanExecution{} = plan_execution
      ) do
    message = {:created, plan_execution}

    Phoenix.PubSub.broadcast(Smokex.PubSub, "#{plan_definition_id}", message)
    Phoenix.PubSub.broadcast(Smokex.PubSub, "#{organization_id}", message)
  end

  @doc """
  Sends a broadcast message for the given plan execution.
  """
  @spec notify_change({:ok, PlanExecution.t()} | {:error, term}, PlanExecution.status()) ::
          {:ok, PlanExecution.t()} | {:error, term}
  def notify_change(result, event) do
    with {:ok, plan_execution} <- result do
      Phoenix.PubSub.broadcast(
        Smokex.PubSub,
        "#{plan_execution.id}",
        {event, plan_execution}
      )
    else
      _ ->
        # TODO check if the error handling is needed and if it should notify an
        # error
        :ok
    end

    result
  end
end
