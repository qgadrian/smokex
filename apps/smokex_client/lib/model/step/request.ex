defmodule SmokexClient.Step.Request do
  @type t :: %__MODULE__{
          action: atom,
          host: String.t(),
          query: map,
          body: map,
          expect: SmokexClient.Step.Request.Expect.t(),
          headers: map,
          save_from_response: list(SmokexClient.Step.Request.SaveFromResponse.t()),
          opts: SmokexClient.Step.Request.SaveFromResponse.t()
        }

  defstruct [
    :action,
    :host,
    query: %{},
    body: %{},
    expect: %SmokexClient.Step.Request.Expect{},
    headers: %{},
    save_from_response: [],
    opts: []
  ]
end
