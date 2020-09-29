defmodule Smokex.Results do
  @moduledoc """
  Context module to work with [results](`t:#{HTTPRequestResult}/0`).
  """

  require Logger

  alias Smokex.Results.HTTPRequestResult
  alias Smokex.PlanExecution

  @spec create(map) :: {:ok, HTTPRequestResult.t()} | {:error, Ecto.Changeset.t()}
  def create(%{plan_execution: %PlanExecution{id: plan_execution_id}} = attrs) do
    result =
      %HTTPRequestResult{}
      |> HTTPRequestResult.changeset(attrs)
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

  @doc """
  Return whether the result has failed assertions.
  """
  @spec has_failed?(HTTPRequestResult.t()) :: boolean
  def has_failed?(%HTTPRequestResult{failed_assertions: map}) when map == %{}, do: false
  def has_failed?(%HTTPRequestResult{failed_assertions: nil}), do: false
  def has_failed?(%HTTPRequestResult{failed_assertions: []}), do: false
  def has_failed?(%HTTPRequestResult{failed_assertions: _}), do: true
end
