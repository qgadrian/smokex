defmodule SmokexClient.Utils.StepVarsReplacerTest do
  use ExUnit.Case

  alias SmokexClient.Utils.StepVarsReplacer

  describe "process_step_variables/2" do
    test "replaces only the variables that match `${xxx}`" do
      mock_structs = [
        %Smokex.Step.Request{
          action: "get",
          host: "http://my.host/${env_var_test}",
          query: %{},
          expect: nil,
          headers: %{}
        },
        %Smokex.Step.Request{
          action: "${env_var_test}",
          host: "http://my.host/${env_var_test}",
          query: %{},
          expect: nil,
          headers: %{}
        }
      ]

      expected_result_state = [
        %Smokex.Step.Request{
          action: "get",
          host: "http://my.host/a_var_test_value",
          query: %{},
          expect: nil,
          headers: %{}
        },
        %Smokex.Step.Request{
          action: "a_var_test_value",
          host: "http://my.host/a_var_test_value",
          query: %{},
          expect: nil,
          headers: %{}
        }
      ]

      assert expected_result_state ==
               StepVarsReplacer.process_step_variables(mock_structs, %{
                 "env_var_test" => "a_var_test_value"
               })
    end
  end

  test "Given a struct list when it has environment variables then the struct list with the replace environment is returned" do
    System.put_env("ENV_VAR_TEST", "a_var_test_value")

    mock_structs = [
      %Smokex.Step.Request{
        action: "get",
        host: "${ENV_VAR_TEST}",
        query: %{},
        expect: nil,
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "put",
        host: "ENV_VAR_TEST",
        query: %{},
        expect: nil,
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "post",
        host: "$ENV_VAR_TEST",
        query: %{},
        expect: nil,
        headers: %{}
      }
    ]

    expected_result_state = [
      %Smokex.Step.Request{
        action: "get",
        host: "a_var_test_value",
        query: %{},
        expect: nil,
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "put",
        host: "ENV_VAR_TEST",
        query: %{},
        expect: nil,
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "post",
        host: "$ENV_VAR_TEST",
        query: %{},
        expect: nil,
        headers: %{}
      }
    ]

    assert expected_result_state == StepVarsReplacer.process_step_variables(mock_structs)
  end

  test "Given a struct list when it does not have environment variables then the struct list with the replace environment is returned" do
    System.put_env("ENV_VAR_TEST", "a_var_test_value")

    mock_structs = [
      %Smokex.Step.Request{
        action: "get",
        host: "test",
        query: %{},
        expect: nil,
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "put",
        host: "ENV_VAR_TEST",
        query: %{},
        expect: nil,
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "post",
        host: "$ENV_VAR_TEST",
        query: %{},
        expect: nil,
        headers: %{}
      }
    ]

    expected_result_state = [
      %Smokex.Step.Request{
        action: "get",
        host: "test",
        query: %{},
        expect: nil,
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "put",
        host: "ENV_VAR_TEST",
        query: %{},
        expect: nil,
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "post",
        host: "$ENV_VAR_TEST",
        query: %{},
        expect: nil,
        headers: %{}
      }
    ]

    assert expected_result_state == StepVarsReplacer.process_step_variables(mock_structs)
  end

  test "Given a struct list when it a expect then returns the request with the expect" do
    System.put_env("ENV_VAR_TEST", "a_var_test_value")

    mock_structs = [
      %Smokex.Step.Request{
        action: "get",
        host: "test",
        query: %{},
        expect: %Smokex.Step.Request.Expect{},
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "put",
        host: "ENV_VAR_TEST",
        query: %{},
        expect: %Smokex.Step.Request.Expect{},
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "post",
        host: "$ENV_VAR_TEST",
        query: %{},
        expect: %Smokex.Step.Request.Expect{},
        headers: %{}
      }
    ]

    expected_result_state = [
      %Smokex.Step.Request{
        action: "get",
        host: "test",
        query: %{},
        expect: %Smokex.Step.Request.Expect{},
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "put",
        host: "ENV_VAR_TEST",
        query: %{},
        expect: %Smokex.Step.Request.Expect{},
        headers: %{}
      },
      %Smokex.Step.Request{
        action: "post",
        host: "$ENV_VAR_TEST",
        query: %{},
        expect: %Smokex.Step.Request.Expect{},
        headers: %{}
      }
    ]

    assert expected_result_state == StepVarsReplacer.process_step_variables(mock_structs)
  end
end
