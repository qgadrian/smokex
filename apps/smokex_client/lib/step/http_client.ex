defmodule SmokexClient.Step.HttpClient do
  @moduledoc """
  Module responsible to generate the HTTP client.
  """
  require Logger

  alias Smokex.Step.Request

  @doc """
  Returns a new `t:Tesla.Client.t/0`.

  The client contains middleware with the needed request information from the
  given request struct.
  """
  @spec new(Request.t()) :: Tesla.Client.t()
  def new(%Request{} = step) do
    step
    |> build_middleware()
    |> Tesla.client(build_adapter())
  end

  @doc """
  Sends the given request and returns the response.

  If the request is invalid or there is any error raised this function will
  wrap the raised error and return a tuple with the error wrapped.
  """
  @spec request(Request.t()) :: Tesla.Env.result()
  def request(%Request{} = step) do
    step
    |> __MODULE__.new()
    |> Tesla.request(
      method: step.action,
      url: step.host,
      body: get_body(step.body, step.action)
    )
  rescue
    error ->
      Logger.error(inspect(error))
      {:error, "Error executing request"}
  end

  #
  # Private functions
  #

  @spec get_body(String.t() | map, atom) :: String.t()
  defp get_body(_, :get), do: nil
  defp get_body(body, _action), do: Jason.encode!(body)

  @spec build_adapter() :: term
  defp build_adapter, do: {Tesla.Adapter.Hackney, insecure: true}

  @spec build_middleware(Request.t()) :: list
  defp build_middleware(%Request{} = step) do
    maybe_json_middleware =
      if is_binary(step.expect.body) do
        nil
      else
        Tesla.Middleware.JSON
      end

    timeout = step.opts[:timeout] || Application.get_env(:smokex_client, :timeout)

    [
      maybe_json_middleware,
      {Tesla.Middleware.Logger, debug: true, log_level: :info},
      {Tesla.Middleware.Query, Map.to_list(step.query)},
      {Tesla.Middleware.Headers, Map.to_list(step.headers)},
      {Tesla.Middleware.Timeout, timeout: timeout},
      Tesla.Middleware.Telemetry
    ]
    |> Enum.reject(&is_nil/1)
  end
end
