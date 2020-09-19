defmodule SmokexClient.Test.Workers.Yaml do
  use ExUnit.Case, async: true

  #
  # There are `error case` scenarios here and the log messages are not being
  # asserted at the moment. For this reason, all logs will be captured to avoid
  # adding noise to tests.
  #
  # https://hexdocs.pm/ex_unit/ExUnit.Case.html#module-module-and-describe-tags
  @moduletag capture_log: true

  import Smokex.TestSupport.Factories

  alias SmokexClient.Executor
  alias Smokex.Result
  alias Smokex.PlanExecution
  alias Smokex.PlanExecutions

  defp create_plan_execution(yaml_file_path) do
    plan_definition = insert(:plan_definition, content: File.read!(yaml_file_path))
    plan_execution = insert(:plan_execution, plan_definition: plan_definition)

    PlanExecutions.subscribe(plan_execution)

    plan_execution
  end

  test "the organization secrets are used in the context execution" do
    secrets = [
      build(:organization_secret, name: "TEST_VAR", value: "203"),
      build(:organization_secret, name: "EXPECT_TEST_VAR", value: "203")
    ]

    organization = insert(:organization, secrets: secrets)

    plan_definition =
      insert(:plan_definition,
        organization: organization,
        content: File.read!("test/support/fixtures/worker/yaml/test_context_variables.yml")
      )

    %PlanExecution{id: id} =
      plan_execution = insert(:plan_execution, plan_definition: plan_definition)

    PlanExecutions.subscribe(plan_execution)

    Executor.execute(plan_execution)

    assert_receive {:started, %PlanExecution{id: ^id}}

    assert_receive {:result,
                    %Result{action: :get, host: "https://localhost:5743/status/203", result: :ok}}

    assert_receive {:finished, %PlanExecution{id: ^id}}
  end

  test "Given a yaml steps when launch worker then each valid step is processed" do
    %PlanExecution{id: id} =
      plan_execution =
      create_plan_execution("test/support/fixtures/worker/yaml/test_valid_steps.yml")

    Executor.execute(plan_execution)

    assert_receive {:started, %PlanExecution{id: ^id}}

    assert_receive {:result,
                    %Result{action: :get, host: "https://localhost:5743/get", result: :ok}}

    assert_receive {:result,
                    %Result{action: :post, host: "https://localhost:5743/post", result: :ok}}

    assert_receive {:result,
                    %Result{action: :get, host: "https://localhost:5743/status/204", result: :ok}}

    assert_receive {:finished, %PlanExecution{id: ^id}}
  end

  test "Given a yaml steps when it has a failing step then an error is returned" do
    %PlanExecution{id: id} =
      plan_execution =
      create_plan_execution("test/support/fixtures/worker/yaml/test_request_internal_error.yml")

    Executor.execute(plan_execution)

    assert_receive {:started, %PlanExecution{id: ^id}}

    assert_receive {:result,
                    %Result{
                      action: :get,
                      host: "https://localhost:5743/status/500",
                      failed_assertions: [
                        %{
                          status_code: %{expected: [200, 201, 202, 203, 204], received: 500}
                        }
                      ],
                      result: :error
                    }}

    assert_receive {:halted, %PlanExecution{id: ^id}}
  end

  test "Given a yaml with an expect code when a response returns the same code then an error is returned" do
    %PlanExecution{id: id} =
      plan_execution =
      create_plan_execution("test/support/fixtures/worker/yaml/test_status_code.yml")

    Executor.execute(plan_execution)

    assert_receive {:started, %PlanExecution{id: ^id}}

    assert_receive {:result,
                    %Result{action: :get, host: "https://localhost:5743/status/423", result: :ok}}

    assert_receive {:finished, %PlanExecution{id: ^id}}
  end

  test "Given a yaml with an expect code when a response returns a different code then an error is returned" do
    %PlanExecution{id: id} =
      plan_execution =
      create_plan_execution("test/support/fixtures/worker/yaml/test_status_code_error.yml")

    Executor.execute(plan_execution)

    assert_receive {:started, %PlanExecution{id: ^id}}

    assert_receive {:result,
                    %Result{
                      action: :get,
                      host: "https://localhost:5743/get",
                      failed_assertions: [%{status_code: %{expected: 400, received: 200}}],
                      result: :error
                    }}

    assert_receive {:halted, %PlanExecution{id: ^id}}
  end

  test "Given a yaml when it contains an invalid host then an error is returned" do
    %PlanExecution{id: id} =
      plan_execution =
      create_plan_execution("test/support/fixtures/worker/yaml/test_invalid_host.yml")

    Executor.execute(plan_execution)

    assert_receive {:started, %PlanExecution{id: ^id}}

    assert_receive {:result,
                    %Result{
                      action: :get,
                      host: "invalid_host",
                      failed_assertions: [%{error: "Invalid host"}],
                      result: :error
                    }}

    assert_receive {:halted, %PlanExecution{id: ^id}}
  end

  test "Given a yaml with an header when the response does not return the header then an error is returned" do
    %PlanExecution{id: id} =
      plan_execution =
      create_plan_execution("test/support/fixtures/worker/yaml/test_headers_error.yml")

    Executor.execute(plan_execution)

    assert_receive {:started, %PlanExecution{id: ^id}}

    assert_receive {:result,
                    %Result{
                      action: :get,
                      host: "https://localhost:5743/status/202",
                      failed_assertions: [
                        %{headers: [%{header: "a_header", expected: "a_value", received: nil}]}
                      ],
                      result: :error
                    }}

    assert_receive {:halted, %PlanExecution{id: ^id}}
  end

  test "Given a yaml with an expected header and status code when the response does not return none of them then an error is returned" do
    %PlanExecution{id: id} =
      plan_execution =
      create_plan_execution(
        "test/support/fixtures/worker/yaml/test_status_code_and_headers_error.yml"
      )

    Executor.execute(plan_execution)

    expeted_header = %{headers: [%{header: "a_header", expected: "a_value", received: nil}]}
    expeted_status_code = %{status_code: %{expected: 523, received: 202}}
    expected_assertions = [Map.merge(expeted_header, expeted_status_code)]

    assert_receive {:started, %PlanExecution{id: ^id}}

    assert_receive {:result,
                    %Result{
                      action: :get,
                      host: "https://localhost:5743/status/202",
                      failed_assertions: ^expected_assertions,
                      result: :error
                    }}

    assert_receive {:halted, %PlanExecution{id: ^id, status: :halted}}
  end

  describe "Given a yaml plan" do
    test "when a request takes more time than the configured timeout then an error is returned" do
      %PlanExecution{id: id} =
        plan_execution =
        create_plan_execution("test/support/fixtures/worker/yaml/test_timeout_opt.yml")

      Executor.execute(plan_execution)

      assert_received {:started, %PlanExecution{id: ^id}}

      assert_receive {:result,
                      %Result{
                        action: :get,
                        host: "http://httpbin.org/delay/2",
                        failed_assertions: [%{error: :timeout}],
                        result: :error
                      }}

      assert_receive {:halted, %PlanExecution{id: ^id, status: :halted}}
    end

    test "when the body is a string then the body string is sent in the request" do
      %PlanExecution{id: id} =
        plan_execution =
        create_plan_execution("test/support/fixtures/worker/yaml/test_body_string.yml")

      Executor.execute(plan_execution)

      assert_received {:started, %PlanExecution{id: ^id}}

      assert_receive {:result,
                      %Result{
                        action: :post,
                        host: "https://localhost:5743/post",
                        result: :ok
                      }}

      assert_receive {:finished, %PlanExecution{id: ^id, status: :finished}}
    end

    test "when save a response and the var key is used in another request then the request sends the var value" do
      %PlanExecution{id: id} =
        plan_execution =
        create_plan_execution("test/support/fixtures/worker/yaml/test_save_from_response.yml")

      Executor.execute(plan_execution)

      assert_receive {:started, %PlanExecution{id: ^id}}

      assert_receive {:result,
                      %Result{action: :post, host: "https://localhost:5743/post", result: :ok}}

      assert_receive {:result,
                      %Result{action: :get, host: "https://localhost:5743/headers", result: :ok}}

      assert_receive {:finished, %PlanExecution{id: ^id, status: :finished}}
    end
  end
end
