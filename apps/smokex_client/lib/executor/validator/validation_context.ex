defmodule SmokexClient.Validator.ValidationContext do
  @moduledoc """
  Represents the context of a validation.

  This struct contains a list of the result of any kind of validation
  performed.

  If `validation_errors` is an empty list, the validation context is considered
  as success.
  """

  alias SmokexClient.Validator.Validation

  @type t :: %__MODULE__{
          validation_errors: list(Validation.t())
        }

  defstruct validation_errors: []
end
