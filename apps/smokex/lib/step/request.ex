defmodule Smokex.Step.Request do
  @type opts :: :timeout

  @type t :: %__MODULE__{
          action: atom,
          body: map,
          expect: Smokex.Step.Request.Expect.t(),
          headers: map,
          host: String.t(),
          opts: %{opts => term},
          query: map,
          save_from_response: list(Smokex.Step.Request.SaveFromResponse.t())
        }

  defstruct [
    :action,
    :host,
    query: %{},
    body: %{},
    expect: %Smokex.Step.Request.Expect{},
    headers: %{},
    save_from_response: [],
    opts: []
  ]
end
