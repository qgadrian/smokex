defmodule SmokexWeb.PlanExecutions.Components.FilterView do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  # disabled
  # active
  @default_class "list-group-item list-group-item-action d-flex justify-content-between align-items-center hover-cursor"

  @typep filter_name :: PlanExecution.state() | String.t()

  @spec plan_execution_filter(atom, filter_name) :: Phoenix.HTML.Tag.t()
  def plan_execution_filter(:all, active_filter) do
    filter_tag("All", :all, active_filter)
  end

  def plan_execution_filter(:created, active_filter) do
    filter_tag("Created", :created, active_filter)
  end

  def plan_execution_filter(:finished, active_filter) do
    filter_tag("Finished", :finished, active_filter)
  end

  def plan_execution_filter(:halted, active_filter) do
    filter_tag("Halted", :halted, active_filter)
  end

  def plan_execution_filter(:running, active_filter) do
    filter_tag("Running", :running, active_filter)
  end

  defp filter_tag(label, filter_name, active_filter) do
    class =
      if is_active(filter_name, active_filter) do
        "#{@default_class} active"
      else
        @default_class
      end

    content_tag :a, class: class, phx_click: "filter_executions", phx_value_filter: filter_name do
      [
        content_tag(:span, label)
      ]
    end
  end

  defp is_active(filter_name, active_filter) when is_atom(active_filter) do
    active_filter == filter_name
  end

  defp is_active(filter_name, active_filter) when is_binary(active_filter) do
    String.to_existing_atom(active_filter) == filter_name
  end
end
