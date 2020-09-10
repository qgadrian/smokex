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
  alias SmokexWeb.Telemetry.Reporter, as: TelemetryReporter

  @doc """
  Creates a new user in the database and a new organization associated to it.
  """
  @spec create(map) :: {:ok, User.t()} | {:error, term}
  def create(params) do
    # TODO use `Ecto.Multi`
    with {:ok, %User{} = user} = result <- pow_create(params) do
      {:ok, _organization} = Organizations.create("organization_#{user.id}", user)

      TelemetryReporter.execute([:user], %{new: 1}, %{id: user.id})

      result
    else
      error -> error
    end
  end

  @doc """
  Returns whether the user has an premium access to the application.

  If the user is `nil` (is unauthenticated) or not subscribed, then the
  `free_access` config is checkd as fallback to grant access to premium
  features.
  """
  @spec subscribed?(User.t()) :: boolean
  def subscribed?(nil) do
    Application.get_env(:smokex, :free_access, false)
  end

  def subscribed?(%User{subscription_expires_at: nil}) do
    Application.get_env(:smokex, :free_access, false)
  end

  def subscribed?(%User{subscription_expires_at: subscription_expires_at}) do
    is_free_access = Application.get_env(:smokex, :free_access, false)

    if is_free_access do
      true
    else
      subscription_expires_at
      |> DateTime.compare(DateTime.utc_now())
      |> case do
        :gt -> true
        :eq -> true
        :lt -> false
      end
    end
  end
end
