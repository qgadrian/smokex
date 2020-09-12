defmodule SmokexWeb.PlanExecutions.Components.RuntimeLabel do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  @default_class "is-size-7 pl-1"

  def new(%PlanExecution{status: :running}) do
    content_tag(:span, "In progress", class: "#{@default_class} is-italic")
  end

  def new(%PlanExecution{finished_at: nil}) do
    content_tag(:span, "...", class: @default_class)
  end

  def new(plan) do
    duration = Timex.diff(plan.finished_at, plan.started_at, :duration)
     |> Timex.format_duration(:humanized)
    content_tag(:span, duration , class: @default_class)
  end
end
