defmodule Smokex.Users do
  # For overridable functions see:
  # https://github.com/danschultzer/pow/blob/master/lib/pow/ecto/context.ex
  use Pow.Ecto.Context,
    repo: Smokex.Repo,
    user: Smokex.Users.User

  alias Smokex.Users.User
  alias Smokex.Organizations
  alias SmokexWeb.Telemetry.Reporter, as: TelemetryReporter

  @spec create(map) :: {:ok, User.t()} | {:error, term}
  def create(params) do
    with {:ok, %User{} = user} = result <- pow_create(params) do
      Organizations.create("organization_#{user.id}", user)

      TelemetryReporter.execute([:user], %{new: 1}, %{id: user.id})

      result
    else
      error -> error
    end
  end

  @doc """
  Gets a user by the given fields.

  If no user is found, returns `nil`.
  """
  @spec get_by(keyword) :: User.t()
  def get_by(params) do
    Smokex.Repo.get_by(User, params)
  end

  @doc """
  Updates a user.

  ## Examples
      iex> update(user, %{stripe_id: "test"})
      {:ok, %User{}}
      iex> update(user, %{stripe_id: 1234})
      {:error, %Ecto.Changeset{}}
  """
  @spec update(User.t(), map) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update(%User{} = user, params) do
    user
    |> User.update_changeset(params)
    |> Smokex.Repo.update()
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
