defmodule Smokex.Step.Request.Expect do
  @typedoc """
  A HTML expect option.

  The `path` will be used as a CSS selector, asserting the value present with
  the `equal` value.
  """
  @type html_opt :: %{
          required(:path) => String.t(),
          required(:equal) => String.t() | number | boolean
        }

  @type t :: %__MODULE__{
          status_code: non_neg_integer,
          headers: map,
          body: map | String.t(),
          html: list(html_opt)
        }

  defstruct [
    :status_code,
    :headers,
    :body,
    :html
  ]

  @spec new(map) :: %__MODULE__{}
  def new(attrs), do: struct(__MODULE__, attrs)
end
