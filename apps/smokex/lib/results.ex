defmodule Smokex.Results do
  @moduledoc """
  Context module to work with [results](`t:#{Result}/0`).
  """

  alias Smokex.Result

  @spec create(map) :: {:ok, Result.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %Result{}
    |> Result.changeset(attrs)
    |> Smokex.Repo.insert()
  end
end
