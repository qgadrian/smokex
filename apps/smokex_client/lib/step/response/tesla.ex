defimpl Smokex.Step.Response.ResponseBuilder, for: Tesla.Env do
  alias Smokex.Results.HTTPResponse

  @spec build(Tesla.Env.t(), keyword) :: HTTPResponse.t()
  def build(
        %Tesla.Env{} = http_client_response,
        opts
      ) do
    started_at = Keyword.fetch!(opts, :started_at)

    %HTTPResponse{
      body: body_as_string(http_client_response.body),
      headers: Enum.into(http_client_response.headers, %{}),
      query: Enum.into(http_client_response.query, %{}),
      status: http_client_response.status,
      started_at: started_at,
      finished_at: Keyword.get(opts, :finished_at, DateTime.utc_now())
    }
  end

  #
  # Private functions
  #

  defp body_as_string(body) when is_map(body), do: Jason.encode!(body)
  defp body_as_string(body) when is_binary(body), do: body
end
