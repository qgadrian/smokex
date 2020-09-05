defmodule SmokexWeb.Telemetry.CurrentSessionCount do
  @moduledoc """
  This module provides the number of current sessions active.
  """

  alias SmokexWeb.Telemetry.Reporter

  @doc """
  Returns the number of current active user sessions.
  """
  @spec dispatch_session_count :: :ok
  def dispatch_session_count() do
    num_sessions =
      length(Pow.Store.CredentialsCache.users([otp_app: :smokex_web], Smokex.Users.User))

    measurement = %{count: num_sessions}
    metadata = %{}

    Reporter.execute([:session_count], measurement, metadata)
  end
end
