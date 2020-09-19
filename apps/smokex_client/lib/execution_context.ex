defmodule SmokexClient.ExecutionContext do
  @moduledoc """
  This module represents the context of an execution.

  The context contains the current state, options, or any configuration for the
  current execution.
  """

  alias Smokex.PlanExecution
  alias SmokexClient.ExecutionContext.Variables

  @halt_on_error Application.compile_env!(:smokex_client, :halt_on_error)

  @type variables :: %{required(String.t()) => String.t() | boolean | number}

  @type t :: %__MODULE__{
          halt_on_error: boolean,
          variables: variables()
        }

  defstruct halt_on_error: @halt_on_error,
            variables: %{}

  @doc """
  Builds a new execution context for the execution using the given options.

  The context will contain as `variables` the organization secrets of the `plan
  execution`.

  The options supported by this function are:

  * `halt`: The execution will halt if a step fails, defaults to `true`.
  """
  @spec new(PlanExecution.t(), keyword) :: __MODULE__.t()
  def new(%PlanExecution{} = plan_execution, opts \\ []) do
    halt_on_error = Keyword.get(opts, :halt, true)
    variables = Variables.from_organization_secrets(plan_execution)

    %__MODULE__{
      halt_on_error: halt_on_error,
      variables: variables
    }
  end
end
