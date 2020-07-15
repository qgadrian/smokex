# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Smokex.Repo.insert!(%Smokex.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

for plan_definition_index <- 1..10 do
  example_file_path = Path.absname("./apps/smokex/priv/repo/plan_definition_content_example.yml")

  {:ok, plan_definition} =
    Smokex.PlanDefinitions.create(%{
      name: "plan_#{plan_definition_index}",
      description: "This is the description for plan #{plan_definition_index}",
      cron_sentence: "0 2 * * *",
      content: File.read!(example_file_path)
    })

  for _ <- 1..10 do
    {:ok, plan_execution} = Smokex.PlanExecutions.create_plan_execution(plan_definition)
  end

  for _ <- 1..5 do
    {:ok, plan_execution} = Smokex.PlanExecutions.create_plan_execution(plan_definition)

    {:ok, _plan_execution} = Smokex.PlanExecutions.start(plan_execution)
    {:ok, _plan_execution} = Smokex.PlanExecutions.finish(plan_execution)
  end

  for _ <- 1..5 do
    {:ok, plan_execution} = Smokex.PlanExecutions.create_plan_execution(plan_definition)

    {:ok, _plan_execution} = Smokex.PlanExecutions.start(plan_execution)
    {:ok, _plan_execution} = Smokex.PlanExecutions.halt(plan_execution)
  end

  for _ <- 1..5 do
    {:ok, plan_execution} = Smokex.PlanExecutions.create_plan_execution(plan_definition)

    {:ok, _plan_execution} = Smokex.PlanExecutions.start(plan_execution)
  end
end
