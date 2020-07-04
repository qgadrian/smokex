defmodule SmokexClient.Test.Workers.Default do
  use ExUnit.Case

  import Smokex.TestSupport.Factories

  alias SmokexClient.Executor

  setup do
    [plan_definition: insert(:plan_definition)]
  end

  test "Given a yaml steps when launch worker then each valid step is processed" do
    {result, _message} = Executor.execute([1, 2, 3])

    assert :error === result
  end
end
