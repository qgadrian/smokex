defmodule Smokex.Subscriptions do
  alias Smokex.Users.User

  @doc """
  Whether the user can create a new plan definition.

  In order to create a new plan definition the user has to have premium access
  or meet the limited configuration.
  """
  @spec renew_subscription(User.t()) :: boolean
  def renew_subscription(%User{} = user) do
    :tbi
  end
end
