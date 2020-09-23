defmodule SmokexWeb.PlanExecutions.Components.StatusBadge do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  @default_class "is-circle"
  @default_icon_class "has-text-white"

  def new(%PlanExecution{status: :created}) do
    content_tag(:span, class: "has-background-dark #{@default_class}") do
      content_tag('ion-icon', "", name: "remove-outline", class: @default_icon_class)
    end
  end

  def new(%PlanExecution{status: :finished}) do
    content_tag(:span, class: "has-background-success #{@default_class}") do
      content_tag('ion-icon', "", name: "checkmark-outline", class: @default_icon_class)
    end
  end

  def new(%PlanExecution{status: :halted}) do
    content_tag(:span, class: "has-background-danger #{@default_class}") do
      content_tag('ion-icon', "", name: "close-outline", class: @default_icon_class)
    end
  end

  def new(%PlanExecution{status: :running}) do
    content_tag(:span, class: "has-background-info #{@default_class}") do
      content_tag('ion-icon', "", name: "sync-outline", class: "icn-spinner #{@default_icon_class}")
    end
  end
end
