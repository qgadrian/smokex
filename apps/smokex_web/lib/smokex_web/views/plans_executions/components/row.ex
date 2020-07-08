defmodule SmokexWeb.PlanExecutions.Components.RowView do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  def status_badge(%PlanExecution{status: :created}) do
    content_tag(:span, "Created", class: "badge badge-secondary")
  end

  def status_badge(%PlanExecution{status: :finished}) do
    content_tag(:span, "Finished", class: "badge badge-success")
  end

  def status_badge(%PlanExecution{status: :halted}) do
    content_tag(:span, "Halted", class: "badge badge-danger")
  end

  def status_badge(%PlanExecution{status: :running}) do
    content_tag(:span, "Running", class: "badge badge-primary")
  end
end
