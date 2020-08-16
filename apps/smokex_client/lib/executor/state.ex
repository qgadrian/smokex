defmodule SmokexClient.Executor.State do
  @moduledoc """
  This module represents the state on a plan execution.
  """

  @type t :: %__MODULE__{
          save_from_responses: map()
        }

  defstruct save_from_responses: %{}
end
