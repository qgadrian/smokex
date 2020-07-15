defmodule SmokexWeb.PlanExecutions.Components.FilterView do
  use SmokexWeb, :view

  alias Smokex.PlanExecution

  @default_class "button is-primary"

  @typep filter_name :: PlanExecution.state() | String.t()

  @spec plan_execution_filter(atom, filter_name, keyword) :: Phoenix.HTML.Tag.t()
  def plan_execution_filter(:all, active_filter, opts) do
    filter_tag("All", :all, active_filter, opts)
  end

  def plan_execution_filter(:created, active_filter, opts) do
    filter_tag("Created", :created, active_filter, opts)
  end

  def plan_execution_filter(:finished, active_filter, opts) do
    filter_tag("Finished", :finished, active_filter, opts)
  end

  def plan_execution_filter(:halted, active_filter, opts) do
    filter_tag("Halted", :halted, active_filter, opts)
  end

  def plan_execution_filter(:running, active_filter, opts) do
    filter_tag("Running", :running, active_filter, opts)
  end

  defp filter_tag(label, filter_name, active_filter, opts) do
    class =
      if is_active(filter_name, active_filter) do
        "#{@default_class} is-selected"
      else
        "#{@default_class} is-outlined"
      end

    content_tag :a,
      class: class,
      href: path_to(filter_name, opts) do
      [
        content_tag(:span, label)
      ]
    end
  end

  defp path_to(filter_name, socket: socket, plan_definition_id: nil) do
    Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.All, filter_name, 1)
  end

  defp path_to(filter_name, socket: socket, plan_definition_id: plan_definition_id) do
    Routes.live_path(socket, SmokexWeb.PlansExecutionsLive.All, filter_name, 1,
      plan: plan_definition_id
    )
  end

  defp is_active(filter_name, active_filter) when is_atom(active_filter) do
    active_filter == filter_name
  end

  defp is_active(filter_name, active_filter) when is_binary(active_filter) do
    String.to_existing_atom(active_filter) == filter_name
  end
end
