defmodule SmokexClient.Utils.StepVarsReplacerTest do
  use ExUnit.Case

  alias SmokexClient.Utils.StepVarsReplacer

  test "Given a struct list when it has environment variables then the struct list with the replace environment is returned" do
    System.put_env("ENV_VAR_TEST", "a_var_test_value")

    mock_structs = [
      %SmokexClient.Step.Request{
        action: "get",
        host: "${ENV_VAR_TEST}",
        query: %{},
        expect: %{},
        headers: %{}
      },
      %SmokexClient.Step.Request{
        action: "put",
        host: "ENV_VAR_TEST",
        query: %{},
        expect: %{},
        headers: %{}
      },
      %SmokexClient.Step.Request{
        action: "post",
        host: "$ENV_VAR_TEST",
        query: %{},
        expect: %{},
        headers: %{}
      }
    ]

    expected_result_state = [
      %SmokexClient.Step.Request{
        action: "get",
        host: "a_var_test_value",
        query: %{},
        expect: %{},
        headers: %{}
      },
      %SmokexClient.Step.Request{
        action: "put",
        host: "ENV_VAR_TEST",
        query: %{},
        expect: %{},
        headers: %{}
      },
      %SmokexClient.Step.Request{
        action: "post",
        host: "$ENV_VAR_TEST",
        query: %{},
        expect: %{},
        headers: %{}
      }
    ]

    assert expected_result_state == StepVarsReplacer.process_step_variables(mock_structs)
  end

  test "Given a struct list when it does not have environment variables then the struct list with the replace environment is returned" do
    System.put_env("ENV_VAR_TEST", "a_var_test_value")

    mock_structs = [
      %SmokexClient.Step.Request{action: "get", host: "test", query: %{}, expect: %{}, headers: %{}},
      %SmokexClient.Step.Request{
        action: "put",
        host: "ENV_VAR_TEST",
        query: %{},
        expect: %{},
        headers: %{}
      },
      %SmokexClient.Step.Request{
        action: "post",
        host: "$ENV_VAR_TEST",
        query: %{},
        expect: %{},
        headers: %{}
      }
    ]

    expected_result_state = [
      %SmokexClient.Step.Request{action: "get", host: "test", query: %{}, expect: %{}, headers: %{}},
      %SmokexClient.Step.Request{
        action: "put",
        host: "ENV_VAR_TEST",
        query: %{},
        expect: %{},
        headers: %{}
      },
      %SmokexClient.Step.Request{
        action: "post",
        host: "$ENV_VAR_TEST",
        query: %{},
        expect: %{},
        headers: %{}
      }
    ]

    assert expected_result_state == StepVarsReplacer.process_step_variables(mock_structs)
  end
end
