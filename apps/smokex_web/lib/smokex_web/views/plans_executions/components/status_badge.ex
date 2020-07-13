defmodule SmokexWeb.PlanExecutions.Components.StatusBadge do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  def new(%PlanExecution{status: :created}) do
    content_tag(:span, "Created", class: "tag is-dark")
  end

  def new(%PlanExecution{status: :finished}) do
    content_tag(:span, "Finished", class: "tag is-success")
  end

  def new(%PlanExecution{status: :halted}) do
    content_tag(:span, "Halted", class: "tag is-danger")
  end

  def new(%PlanExecution{status: :running}) do
    content_tag(:span, "Running", class: "tag is-info")
  end
end

