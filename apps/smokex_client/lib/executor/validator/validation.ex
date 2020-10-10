defmodule SmokexClient.Validator.Validation do
  @moduledoc """
  This module represents a result of a validation.
  """

  @typedoc """
  The result of a validation:

  * `type`: the type of the validation.
  * `name`: the name of the element validated, defaults to `nil`.
  * `expected`: the expected value of the validation.
  * `received`: the received value.
  """
  @type t :: %__MODULE__{
          type: :status_code | :header | :json | :string | :html,
          name: String.t() | nil,
          expected: term,
          received: term
        }

  @enforce_keys [:type, :expected, :received]
  defstruct @enforce_keys ++ [name: nil]
end
