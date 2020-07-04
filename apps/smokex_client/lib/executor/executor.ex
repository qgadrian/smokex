defmodule SmokexClient.Executor do
  alias SmokexClient.ExecutionState
  alias SmokexClient.Worker
  alias SmokexClient.Parsers.Yaml.Parser, as: YamlParser

  alias Smokex.PlanExecutions
  alias Smokex.PlanDefinition

  @spec execute(PlanDefinition.t()) :: {:ok, term} | {:error, term}
  def execute(%PlanDefinition{content: content} = plan_definition) do
    # TODO stop using a process to handle the state here
    ExecutionState.start_link()

    {:ok, plan_execution} = PlanExecutions.create_plan_execution(plan_definition)

    # TODO this code is currently expecting a YAML file, but the parser could
    # be different depending on the type of content
    plan_definition
    |> Map.get(:content)
    |> YamlParser.parse()
    |> case do
      {:ok, list_of_requests} ->
        try do
          Enum.each(list_of_requests, &Worker.execute(&1, plan_execution))

          PlanExecutions.update_plan_execution(plan_execution, %{status: :finished})
        catch
          {:error, reason} ->
            PlanExecutions.update_plan_execution(plan_execution, %{status: :halted})
        end

      {:error, message} ->
        PlanExecutions.update_plan_execution(plan_execution, %{status: :halted})
    end
  end
end
