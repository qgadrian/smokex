defmodule SmokexWeb.Results.Components.StatusBadge do
  use SmokexWeb, :view

  alias Smokex.Result

  @default_class "is-circle"
  @default_icon_class "has-text-white"

  @spec new(Result.t()) :: term
  def new(%Result{result: :ok}) do
    content_tag(:span, class: "has-background-success #{@default_class}") do
      content_tag('ion-icon', "", name: "checkmark-outline", class: @default_icon_class)
    end
  end

  def new(%Result{result: :error}) do
    content_tag(:span, class: "has-background-danger #{@default_class}") do
      content_tag('ion-icon', "", name: "close-outline", class: @default_icon_class)
    end
  end
end
