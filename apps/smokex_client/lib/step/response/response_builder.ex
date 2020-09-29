defprotocol Smokex.Step.Response.ResponseBuilder do
  alias Smokex.Results.HTTPResponse

  @doc """
  Builds a new `t:#{HTTPResponse}.t/0`.
  """
  @fallback_to_any true
  def build(http_client_response, opts)
end

defimpl Smokex.Step.Response.ResponseBuilder, for: Any do
  @spec build(any, keyword) :: no_return
  def build(_any, _opts) do
    throw({:error, "Missing implementation"})
  end
end
