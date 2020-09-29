defmodule SmokexWeb.Results.Components.StatusBadge do
  use SmokexWeb, :view

  alias Smokex.Results.HTTPRequestResult

  @default_class "is-circle"
  @default_icon_class "has-text-white"

  @spec new(HTTPRequestResult.t()) :: term
  def new(%HTTPRequestResult{result: :ok}) do
    content_tag(:span, class: "has-background-success #{@default_class}") do
      content_tag('ion-icon', "", name: "checkmark-outline", class: @default_icon_class)
    end
  end

  def new(%HTTPRequestResult{result: :error}) do
    content_tag(:span, class: "has-background-danger #{@default_class}") do
      content_tag('ion-icon', "", name: "close-outline", class: @default_icon_class)
    end
  end
end
