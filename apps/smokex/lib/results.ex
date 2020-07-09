defmodule Smokex.Results do
  @moduledoc """
  Context module to work with [results](`t:#{Result}/0`).
  """

  require Logger

  alias Smokex.Result
  alias Smokex.PlanExecution

  @spec create(map) :: {:ok, Result.t()} | {:error, Ecto.Changeset.t()}
  def create(%{plan_execution: %PlanExecution{id: plan_execution_id}} = attrs) do
    result =
      %Result{}
      |> Result.changeset(attrs)
      |> Smokex.Repo.insert()

    with {:ok, result} <- result do
      Phoenix.PubSub.broadcast(
        Smokex.PubSub,
        "#{plan_execution_id}",
        {:result, result}
      )
    else
      _ ->
        Logger.error("Error creating result: #{inspect(result)}")
    end

    result
  end
end
