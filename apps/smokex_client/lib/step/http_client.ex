defmodule SmokexClient.Step.HttpClient do
  @moduledoc """
  Module responsible to generate the HTTP client.
  """

  alias Smokex.Step.Request

  @doc """
  Returns a new `t:Tesla.Client.t/0`.

  The client contains middleware with the needed request information from the
  given request struct.
  """
  @spec new(Request.t()) :: Tesla.Client.t()
  def new(%Request{} = step) do
    step
    |> build_middlware
    |> Tesla.client(build_adapter())
  end

  @spec request(Request.t()) :: Tesla.Env.result()
  def request(%Request{} = step) do
    step
    |> __MODULE__.new()
    |> Tesla.request(
      method: step.action,
      url: step.host,
      body: get_body(step.body, step.action)
    )
  end

  #
  # Private functions
  #

  @spec get_body(String.t() | map, atom) :: String.t()
  defp get_body(_, :get), do: nil
  defp get_body(body, _action), do: Jason.encode!(body)

  @spec build_adapter() :: term
  defp build_adapter, do: {Tesla.Adapter.Hackney, insecure: true}

  @spec build_middlware(Request.t()) :: list
  defp build_middlware(%Request{} = step) do
    maybe_json_middleware =
      if is_binary(step.expect.body) do
        nil
      else
        Tesla.Middleware.JSON
      end

    [
      maybe_json_middleware,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Query, Map.to_list(step.query)},
      {Tesla.Middleware.Headers, Map.to_list(step.headers)},
      {Tesla.Middleware.Timeout, timeout: 2_000}
    ]
    |> Enum.reject(&is_nil/1)
  end
end
