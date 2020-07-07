defmodule SmokexWeb.PlanExecutions.Components.FilterView do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  # disabled
  # active
  @default_class "list-group-item list-group-item-action d-flex justify-content-between align-items-center hover-cursor"

  @spec plan_execution_filter(atom, list(PlanExecution.t()), boolean) :: Phoenix.HTML.Tag.t()
  def plan_execution_filter(:all, plan_executions, active_filter) do
    plan_executions
    |> count_by(:all)
    |> filter_tag("All", active_filter == :all)
  end

  def plan_execution_filter(:created, plan_executions, active_filter) do
    plan_executions
    |> count_by(:created)
    |> filter_tag("Created", active_filter == :created)
  end

  def plan_execution_filter(:finished, plan_executions, active_filter) do
    plan_executions
    |> count_by(:finished)
    |> filter_tag("Finished", active_filter == :finished)
  end

  def plan_execution_filter(:halted, plan_executions, active_filter) do
    plan_executions
    |> count_by(:halted)
    |> filter_tag("Halted", active_filter == :halted)
  end

  def plan_execution_filter(:running, plan_executions, active_filter) do
    plan_executions
    |> count_by(:running)
    |> filter_tag("Running", active_filter == :running)
  end

  defp filter_tag(number_of_items, label, is_active) do
    class =
      if is_active do
        "#{@default_class} active"
      else
        @default_class
      end

    content_tag :a, class: class do
      [
        content_tag(:span, label),
        content_tag(:span, number_of_items, class: "badge badge-secondary badge-pill")
      ]
    end
  end

  defp count_by(plan_executions, :all), do: length(plan_executions)

  defp count_by(plan_executions, status) do
    Enum.count(plan_executions, fn
      %PlanExecution{status: ^status} -> true
      _ -> false
    end)
  end
end
