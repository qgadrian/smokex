defmodule SmokexWeb.Results.Components.ActionBadge do
  use SmokexWeb, :view

  alias Smokex.Result

  @default_class "tag is-light is-capitalized has-text-weight-medium"

  @spec new(Result.t()) :: term
  def new(%Result{action: action}) when action in [:get] do
    text = build_text(action)

    content_tag(:span, text, class: "#{@default_class} is-success")
  end

  def new(%Result{action: action}) when action in [:delete] do
    text = build_text(action)

    content_tag(:span, text, class: "#{@default_class} is-danger")
  end

  def new(%Result{action: action}) do
    text = build_text(action)

    content_tag(:span, text, class: "#{@default_class} is-info")
  end

  #
  # Private functions
  #

  @spec build_text(atom) :: String.t()
  defp build_text(action) when is_atom(action) do
    Atom.to_string(action) |> String.upcase()
  end
end
