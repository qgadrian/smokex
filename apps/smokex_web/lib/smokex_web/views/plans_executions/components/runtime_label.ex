defmodule SmokexWeb.PlanExecutions.Components.RuntimeLabel do
  use SmokexWeb, :view

  alias Smokex.PlanExecutions
  alias Smokex.PlanExecution

  @default_class "is-size-7 pl-1"

  @spec new(PlanExecution.t()) :: term
  def new(%PlanExecution{status: :running}) do
    content_tag(:span, "In progress", class: "#{@default_class} is-italic")
  end

  def new(%PlanExecution{finished_at: finished_at, started_at: started_at})
      when is_nil(finished_at) or is_nil(started_at) do
    content_tag(:span, "...", class: @default_class)
  end

  def new(%PlanExecution{} = plan_execution) do
    duration =
      plan_execution
      |> PlanExecutions.execution_time()
      |> Timex.Duration.from_seconds()
      |> Timex.format_duration(:humanized)

    content_tag(:span, duration, class: @default_class)
  end
end
