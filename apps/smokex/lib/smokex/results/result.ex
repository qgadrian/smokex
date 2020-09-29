defmodule Smokex.Result do
  @moduledoc """
  This module contains the information after a
  [request](`t:Smokex.Step.Request/0`) is executed.
  """

  use Ecto.Schema

  alias Smokex.Step.RequestActionEnum
  alias Smokex.Step.RequestResultEnum
  alias Smokex.PlanExecution
  alias Smokex.Results.HTTPResponse

  @typedoc """
  The result status of an execution step
  """
  @type result :: :ok | :error

  @typedoc """
  Represents a result of a [request](`t:Smokex.Step.Request/0`):

  * `action`: [action](`t:#{RequestActionEnum}/0`) that was executed.
  * `host`: A host used in the execution. Defaults to `nil`.
  * `failed_assertions`: List of failed assertions for the execution. Defaults
  to `[]`.
  * `result`: The overall [result](`t:#{RequestResultEnum}/0`) of the
  execution.
  * `response`: The HTTP [response](`t:#{HTTPResponse}.t/0`) from the server.
  """
  @type t :: %__MODULE__{
          action: term,
          host: term,
          response: HTTPResponse.t(),
          failed_assertions: list,
          result: result
        }

  @required_fields [:result]
  @optional_fields [:action, :host, :failed_assertions]

  @schema_fields @required_fields ++ @optional_fields

  schema "plans_executions_http_request_results" do
    field(:action, RequestActionEnum)
    field(:host, :string, default: nil)
    field(:failed_assertions, {:array, :map}, default: [])
    field(:result, RequestResultEnum)

    has_one(:response, HTTPResponse, on_replace: :raise, foreign_key: :result_id)

    belongs_to(:plan_execution, PlanExecution)

    timestamps()
  end

  @spec changeset(__MODULE__.t(), map) :: Ecto.Changeset.t()
  def changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.put_assoc(:plan_execution, params[:plan_execution])
    |> Ecto.Changeset.put_assoc(:response, params[:response])
    |> Ecto.Changeset.assoc_constraint(:plan_execution)
  end
end
