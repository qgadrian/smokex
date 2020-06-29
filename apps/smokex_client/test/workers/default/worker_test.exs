defmodule SmokexClient.Test.Workers.Default do
  use ExUnit.Case

  alias SmokexClient.Executor

  test "Given a yaml steps when launch worker then each valid step is processed" do
    {result, _message} = Executor.execute([1, 2, 3])

    assert :error === result
  end
end
