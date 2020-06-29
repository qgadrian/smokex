defmodule SmokexClient.Step.Request.Expect do
  @type t :: %__MODULE__{
          status_code: non_neg_integer,
          headers: map,
          body: map | String.t()
        }

  defstruct [
    :status_code,
    :headers,
    :body
  ]

  @spec new(map) :: %__MODULE__{}
  def new(attrs), do: struct(__MODULE__, attrs)
end
