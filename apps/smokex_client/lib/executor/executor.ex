defmodule SmokexClient.Executor do
  alias SmokexClient.ExecutionState
  alias SmokexClient.Worker
  alias SmokexClient.Parsers.Yaml.Parser, as: YamlParser

  alias Smokex.PlanExecutions
  alias Smokex.PlanDefinition

  @spec execute(PlanDefinition.t()) :: {:ok, term} | {:error, term}
  def execute(%PlanDefinition{content: content} = plan_definition) do
    {:ok, plan_execution} = PlanExecutions.create_plan_execution(plan_definition)

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
            {:error, reason}
        end

      {:error, message} ->
        PlanExecutions.update_plan_execution(plan_execution, %{status: :halted})
    end
  end

  # TODO do not receive the steps, only the plan definition
  # TODO Change the default get
  @spec execute(list(struct), PlanDefinition.t()) :: :ok | {:error, term}
  def execute(steps, plan_definition \\ Smokex.Repo.all(PlanDefinition) |> List.first()) do
    ExecutionState.start_link()

    {:ok, plan_execution} = PlanExecutions.create_plan_execution(plan_definition)

    try do
      Enum.each(steps, &Worker.execute(&1, plan_execution))

      PlanExecutions.update_plan_execution(plan_execution, %{status: :finished})
    catch
      {:error, reason} ->
        PlanExecutions.update_plan_execution(plan_execution, %{status: :halted})
        {:error, reason}
    end
  end
end
