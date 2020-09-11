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

alias Smokex.PlanExecutions.Status, as: PlanExecutionStatus

# User with premium access
{:ok, pro_user} =
  Smokex.Users.create(%{
    email: "test@local.host",
    password: "fgdfkgmdfkgsfmewsfsd",
    password_confirmation: "fgdfkgmdfkgsfmewsfsd",
    subscription_expires_at: DateTime.from_naive!(~N[2099-05-24 13:26:08.003], "Etc/UTC")
  })

# User with free access
{:ok, free_user} =
  Smokex.Users.create(%{
    email: "user@local.host",
    password: "UuWN8%d*FigS",
    password_confirmation: "UuWN8%d*FigS",
    subscription_expires_at: nil
  })

PowEmailConfirmation.Ecto.Context.confirm_email(pro_user, %{}, otp_app: :smokex_web)
PowEmailConfirmation.Ecto.Context.confirm_email(free_user, %{}, otp_app: :smokex_web)

for plan_definition_index <- 1..10 do
  example_file_path = Path.absname("./apps/smokex/priv/repo/plan_definition_content_example.yml")

  # XXX this needs to be string keys to avoid the mixed keys error. This is
  # because the changeset is using the form from the client, which are string
  # keys.
  {:ok, plan_definition} =
    Smokex.PlanDefinitions.create(pro_user, %{
      "name" => "plan_#{plan_definition_index}",
      "description" => "This is the description for plan #{plan_definition_index}",
      "cron_sentence" => "0 2 * * *",
      "content" => File.read!(example_file_path)
    })

  for _ <- 1..10 do
    {:ok, _plan_execution} =
      Smokex.PlanExecutions.create_plan_execution(pro_user, plan_definition)
  end

  for _ <- 1..5 do
    {:ok, plan_execution} = Smokex.PlanExecutions.create_plan_execution(nil, plan_definition)

    {:ok, _plan_execution} = PlanExecutionStatus.start(plan_execution, 3)
    {:ok, _plan_execution} = PlanExecutionStatus.finish(plan_execution)
  end

  for _ <- 1..5 do
    {:ok, plan_execution} = Smokex.PlanExecutions.create_plan_execution(nil, plan_definition)

    {:ok, _plan_execution} = PlanExecutionStatus.start(plan_execution, 3)
    {:ok, _plan_execution} = PlanExecutionStatus.halt(plan_execution)
  end

  for _ <- 1..5 do
    {:ok, plan_execution} = Smokex.PlanExecutions.create_plan_execution(pro_user, plan_definition)

    {:ok, _plan_execution} = PlanExecutionStatus.start(plan_execution, 3)
  end
end
