defmodule Smokex.Users do
  @moduledoc """
  This module provides context functions to interact with users.

  This module uses `Pow.Ecto.Context` to override the default behaviour of the
  default functions.

  > For a list of all overridable functions see:
  > https://github.com/danschultzer/pow/blob/master/lib/pow/ecto/context.ex
  """

  use Pow.Ecto.Context,
    repo: Smokex.Repo,
    user: Smokex.Users.User

  alias Smokex.Users.User
  alias Smokex.Organizations
  alias Smokex.Organizations.Organization
  alias SmokexWeb.Telemetry.Reporter, as: TelemetryReporter

  @type ecto_user_result :: {:ok, map} | {:error, map}

  @doc """
  Creates a new user in the database and a new organization associated to it.
  """
  @spec create(map) :: ecto_user_result
  def create(params) do
    Smokex.Repo.transaction(fn ->
      with {:ok, %User{} = user} <- pow_create(params),
           {:ok, _organization} <- Organizations.create("organization_#{user.id}", user) do
        report_new_user(user)

        user
      else
        {:error, error} ->
          Smokex.Repo.rollback(error)
      end
    end)
  end

  @doc """
  Returns whether the organization the user belongs to has an premium access to
  the application.

  If the user is `nil` (is unauthenticated), then the `free_access` config is
  checked as fallback to grant access to premium features.
  """
  @spec subscribed?(User.t()) :: boolean
  def subscribed?(nil), do: Application.get_env(:smokex, :free_access, false)

  def subscribed?(%User{} = user) do
    %User{organizations: [%Organization{} = organization]} =
      Smokex.Repo.preload(user, :organizations)

    Organizations.subscribed?(organization)
  end

  #
  # Private functions
  #

  @spec report_new_user(User.t()) :: any
  defp report_new_user(%User{id: user_id} = user) do
    TelemetryReporter.execute([:user], %{new: 1}, %{id: user_id})
  end
end
