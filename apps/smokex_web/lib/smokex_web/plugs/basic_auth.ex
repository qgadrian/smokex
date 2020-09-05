defmodule SmokexWeb.Plugs.BasicAuth do
  @moduledoc """
  This module wraps the `Plug.BasicAuth` module to allow having runtime
  configuration.
  """

  @behaviour Plug

  @impl Plug
  @doc false
  @spec init(Plug.opts()) :: Plug.opts()
  def init(opts), do: opts

  @impl Plug
  @doc """
  Wraps `Plug.BasicAuth.basic_auth/2` with runtime config.
  """
  @spec call(Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, opts) do
    opts_from_config = Application.get_env(:smokex_web, :basic_auth)
    runtime_opts = Keyword.merge(opts, opts_from_config)

    Plug.BasicAuth.basic_auth(conn, runtime_opts)
  end
end
