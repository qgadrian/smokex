defmodule SmokexWeb.PlanExecutions.Components.FilterView do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  # disabled
  # active
  @default_class "list-group-item list-group-item-action d-flex justify-content-between align-items-center hover-cursor"

  def plan_execution_filter(:created, plan_executions) do
    plan_executions
    |> count_by(:created)
    |> filter_tag("Created")
  end

  def plan_execution_filter(:finished, plan_executions) do
    plan_executions
    |> count_by(:finished)
    |> filter_tag("Finished")
  end

  def plan_execution_filter(:halted, plan_executions) do
    plan_executions
    |> count_by(:halted)
    |> filter_tag("Halted")
  end

  def plan_execution_filter(:running, plan_executions) do
    plan_executions
    |> count_by(:running)
    |> filter_tag("Running")
  end

  defp filter_tag(number_of_items, label) do
    content_tag :a, class: @default_class do
      [
        content_tag(:span, label),
        content_tag(:span, number_of_items, class: "badge badge-primary badge-pill")
      ]
    end
  end

  defp count_by(plan_executions, status) do
    Enum.count(plan_executions, fn
      %PlanExecution{status: ^status} -> true
      _ -> false
    end)
  end
end
