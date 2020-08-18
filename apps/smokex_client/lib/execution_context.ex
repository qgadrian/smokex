defmodule SmokexClient.ExecutionContext do
  @moduledoc """
  This module represents the context of an execution.

  The context contains the current state, options, or any configuration for the
  current execution.
  """

  @halt_on_error Application.compile_env!(:smokex_client, :halt_on_error)

  @type t :: %__MODULE__{
          halt_on_error: boolean,
          save_from_responses: map()
        }

  defstruct halt_on_error: @halt_on_error,
            save_from_responses: %{}
end
