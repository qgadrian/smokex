defmodule SmokexWeb.PlanExecutions.Components.TimeAgoLabel do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  def new(%PlanExecution{started_at: nil}) do
    content_tag('time-ago', "not started", class: "no-wrap is-size-7 pl-1 is-italic")
  end

  def new(plan) do
    content_tag('time-ago', Timex.from_now(plan.started_at), class: "no-wrap is-size-7 pl-1")
  end
end
