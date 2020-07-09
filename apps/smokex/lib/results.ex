defmodule Smokex.Results do
  @moduledoc """
  Context module to work with [results](`t:#{Result}/0`).
  """

  alias Smokex.Result

  @spec create(map) :: {:ok, Result.t()} | {:error, Ecto.Changeset.t()}
  def create(%{plan_execution: plan_execution} = attrs) do
    result =
      %Result{}
      |> Result.changeset(attrs)
      |> Smokex.Repo.insert()
      |> notify_result(plan_execution)
  end

  defp notify_result({:ok, %Result{}} = result, plan_execution) do
    Phoenix.PubSub.broadcast(
      Smokex.PubSub,
      "#{plan_execution.id}",
      {:result, plan_execution}
    )

    result
  end

  defp notify_result({:error, _result_changeset} = result, plan_execution) do
    Phoenix.PubSub.broadcast(
      Smokex.PubSub,
      "#{plan_execution.id}",
      {:error, plan_execution}
    )

    result
  end
end
