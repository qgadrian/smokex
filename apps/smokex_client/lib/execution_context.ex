defmodule SmokexClient.ExecutionContext do
  @moduledoc """
  This module represents the context of an execution.

  The context contains the current state, options, or any configuration for the
  current execution.
  """

  @halt_on_error Application.compile_env!(:smokex_client, :halt_on_error)

  @type variables :: %{required(String.t()) => String.t() | boolean | number}

  @type t :: %__MODULE__{
          halt_on_error: boolean,
          variables: variables()
        }

  defstruct halt_on_error: @halt_on_error,
            variables: %{}
end
