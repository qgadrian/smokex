defmodule Smokex.Step.Request.SaveFromResponse do
  @typedoc """
  Saves to a variable name a value from a response:
    - variable_name: The name of the variable to use in any next step
    - json_path: The json path that will match the json response
  """
  @type t :: %__MODULE__{
          variable_name: String.t(),
          json_path: String.t()
        }

  defstruct [:variable_name, :json_path]
end
