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
          status_code: non_neg_integer | nil,
          headers: map | nil,
          string: String.t() | nil,
          json: map | nil,
          html: list(html_opt) | nil
        }

  defstruct [
    :status_code,
    :headers,
    :string,
    :json,
    :html
  ]

  @spec new(map) :: %__MODULE__{}
  def new(attrs), do: struct(__MODULE__, attrs)
end
