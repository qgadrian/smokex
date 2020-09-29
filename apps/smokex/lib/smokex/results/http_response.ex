defmodule Smokex.Results.HTTPResponse do
  @moduledoc """
  This module contains the response information of an executed
  [request](`t:Smokex.Step.Request/0`).
  """

  use Ecto.Schema

  alias Smokex.Results.HTTPRequestResult

  @typedoc """
  Represents a response of a [request](`t:Smokex.Step.Request/0`):
  """
  @type t :: %__MODULE__{
          body: any,
          headers: [{String.t(), String.t()}],
          query: [{String.t() | atom(), String.t()}],
          status: integer,
          started_at: integer,
          finished_at: integer
        }

  @required_fields [:body, :headers, :query, :started_at, :finished_at, :status]

  @schema_fields @required_fields

  schema "plans_executions_http_request_responses" do
    field :body, Smokex.Ecto.EncryptedBinary
    field :headers, Smokex.Ecto.EncryptedMap
    field :query, Smokex.Ecto.EncryptedMap
    field :status, :integer
    field :started_at, :utc_datetime_usec
    field :finished_at, :utc_datetime_usec

    belongs_to(:result, HTTPRequestResult, foreign_key: :result_id)

    timestamps()
  end

  @spec changeset(t(), map) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
  end
end
