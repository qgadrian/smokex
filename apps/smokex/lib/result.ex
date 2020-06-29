defmodule Smokex.Result do
  @moduledoc """
  This module contains the information after a
  [request](`t:Smokex.Step.Request/0`) is executed.
  """

  use Ecto.Schema

  alias Smokex.Step.RequestActionEnum
  alias Smokex.Step.RequestResultEnum

  @typedoc """
  The result status of an execution step
  """
  @type result :: :ok | :error

  @typedoc """
  Represents a result of a [request](`t:Smokex.Step.Request/0`):

  * `action`: [action](`t:#{RequestActionEnum}/0`) that was executed.
  * `host`: A host used in the execution. Defaults to `nil`.
  * `failed_assertions`: List of failed assertions for the execution. Defaults to `[]`.
  * `result`: The overall [result](`t:#{RequestResultEnum}/0`) of the execution.
  """
  @type t :: %__MODULE__{
          action: term,
          host: term,
          failed_assertions: list,
          result: result
        }

  @required_fields [:action, :result]
  @optional_fields [:host, :failed_assertions]

  @schema_fields @required_fields ++ @optional_fields

  schema "execution_steps_results" do
    field(:action, RequestActionEnum)
    field(:host, :string, default: nil)
    field(:failed_assertions, {:array, :map}, default: [])
    field(:result, RequestResultEnum)
  end

  def changeset(changeset, params \\ %{}) do
    changeset
    |> Ecto.Changeset.cast(params, @schema_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
  end
end
