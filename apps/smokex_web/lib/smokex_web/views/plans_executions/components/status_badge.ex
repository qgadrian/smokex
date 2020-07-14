defmodule SmokexWeb.PlanExecutions.Components.StatusBadge do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  @default_class "tag is-small"

  def new(%PlanExecution{status: :created}) do
    content_tag(:span, "Created", class: "#{@default_class} is-dark")
  end

  def new(%PlanExecution{status: :finished}) do
    content_tag(:span, "Finished", class: "#{@default_class} is-success")
  end

  def new(%PlanExecution{status: :halted}) do
    content_tag(:span, "Halted", class: "#{@default_class} is-danger")
  end

  def new(%PlanExecution{status: :running}) do
    content_tag(:span, "Running", class: "#{@default_class} is-info")
  end
end
