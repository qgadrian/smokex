defmodule SmokexWeb.PlanExecutions.Components.Progress do
  use SmokexWeb, :view

  alias Smokex.PlanExecution
  alias Smokex.Result

  @default_class "title is-2 has-text-white"

  @spec total_progress(PlanExecution.t(), list(Result.t())) :: term
  def total_progress(%PlanExecution{total_executions: total_executions}, results) do
    executed = Enum.count(results)
    count = Float.ceil(executed * 100 / total_executions, 2)

    content_tag(:h3, "#{count}%", class: @default_class)
  end

  @spec success(list(Result.t())) :: term
  def success(results) do
    count =
      Enum.count(results, fn
        %Result{result: :ok} -> true
        _ -> false
      end)

    content_tag(:h3, count, class: @default_class)
  end

  @spec failed(list(Result.t())) :: term
  def failed(results) do
    count =
      Enum.count(results, fn
        %Result{result: :error} -> true
        _ -> false
      end)

    content_tag(:h3, count, class: @default_class)
  end
end
