defmodule Smokex.Step.Request do
  @type t :: %__MODULE__{
          action: atom,
          host: String.t(),
          query: map,
          body: map,
          expect: Smokex.Step.Request.Expect.t(),
          headers: map,
          save_from_response: list(Smokex.Step.Request.SaveFromResponse.t()),
          opts: Smokex.Step.Request.SaveFromResponse.t()
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
