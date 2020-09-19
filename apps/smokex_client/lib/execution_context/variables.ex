defmodule SmokexClient.ExecutionContext.Variables do
  @moduledoc """
  This module provides functions to build variables in a execution context.

  The variables can be fetched from different sources:

  * secrets of the `organization` who owns the execution.
  * `the `secrets` of the `workflow` definition~ (not done yet)
  """

  alias SmokexClient.ExecutionContext
  alias Smokex.PlanExecution
  alias Smokex.PlanDefinition
  alias Smokex.Organizations.Organization
  alias Smokex.OrganizationsSecrets
  alias Smokex.Organizations.Secret

  @doc """
  Returns a map containing the secrets of the execution's organization.

  The Organization secrets are stored as string and this function will
  automatically convert the secret value to the relevant type.
  """
  @spec from_organization_secrets(PlanExecution.t()) :: ExecutionContext.variables()
  def from_organization_secrets(%PlanExecution{} = plan_execution) do
    %PlanExecution{plan_definition: %PlanDefinition{organization: %Organization{} = organization}} =
      Smokex.Repo.preload(plan_execution, plan_definition: :organization)

    organization
    |> OrganizationsSecrets.list()
    |> Enum.map(fn %Secret{name: name, value: value} ->
      {name, convert(value)}
    end)
    |> Enum.into(%{})
  end

  #
  # Private functions
  #

  @spec convert(String.t()) :: boolean | integer | String.t()
  defp convert("true"), do: true
  defp convert("false"), do: false

  defp convert(string_or_number) do
    case Integer.parse(string_or_number) do
      {number, ""} -> number
      _error -> string_or_number
    end
  end
end
