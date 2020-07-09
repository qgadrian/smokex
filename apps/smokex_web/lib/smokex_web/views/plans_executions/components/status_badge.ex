defmodule SmokexWeb.PlanExecutions.Components.StatusBadge do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  def new(%PlanExecution{status: :created}) do
    content_tag(:span, "Created", class: "badge badge-secondary")
  end

  def new(%PlanExecution{status: :finished}) do
    content_tag(:span, "Finished", class: "badge badge-success")
  end

  def new(%PlanExecution{status: :halted}) do
    content_tag(:span, "Halted", class: "badge badge-danger")
  end

  def new(%PlanExecution{status: :running}) do
    content_tag(:span, "Running", class: "badge badge-primary")
  end
end

