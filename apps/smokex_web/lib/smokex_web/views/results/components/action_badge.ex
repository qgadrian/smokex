defmodule SmokexWeb.Results.Components.ActionBadge do
  use SmokexWeb, :view

  alias Smokex.Result

  @default_class "tag is-light is-capitalized has-text-weight-medium"

  @spec new(Result.t()) :: term
  def new(%Result{action: :post}) do
    content_tag(:span, "POST", class: "#{@default_class} is-info")
  end

  @spec new(Result.t()) :: term
  def new(%Result{action: :put}) do
    content_tag(:span, "PUT", class: "#{@default_class} is-info")
  end

  def new(%Result{action: :get}) do
    content_tag(:span, "GET", class: "#{@default_class} is-success")
  end
end
