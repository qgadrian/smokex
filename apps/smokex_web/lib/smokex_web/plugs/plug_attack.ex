defmodule SmokexWeb.Plugs.PlugAttack do
  @moduledoc """
  Module to prevent brute force attacks and throttle the requests based on IP.

  For more information see: https://github.com/michalmuskala/plug_attack
  """

  use PlugAttack

  rule "throttle by ip", conn do
    throttle conn.remote_ip,
      period: 60_000, limit: 20,
      storage: {PlugAttack.Storage.Ets, SmokexWeb.PlugAttack.Storage}
  end
end

