defmodule Smokex.Users do
  alias Smokex.Users.User

  @doc """
  Whether the user can create a new plan definition.

  In order to create a new plan definition the user has to have premium access
  or meet the limited configuration.
  """
  @spec can_create_plan_definition?(User.t()) :: boolean
  def can_create_plan_definition?(%User{} = user) do
    if subscribed?(user) do
      true
    else
      # TODO configure maximum plans value
      user
      |> Smokex.PlanDefinitions.all()
      |> length
      |> Kernel.<(2)
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