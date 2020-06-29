defmodule SmokexClient.Test.Workers.Yaml do
  use ExUnit.Case

  alias SmokexClient.Parsers.Yaml.Parser
  alias SmokexClient.Executor
  alias SmokexClient.ExecutionState
  alias Smokex.Result

  test "Given a yaml steps when launch worker then each valid step is processed" do
    result =
      "test/support/fixtures/worker/yaml/test_valid_steps.yml"
      |> Parser.parse!()
      |> Executor.execute()

    assert :ok === result

    expected_result_state = [
      %Result{action: "get", host: "https://localhost:5743/get", result: :ok},
      %Result{action: "post", host: "https://localhost:5743/post", result: :ok},
      %Result{action: "get", host: "https://localhost:5743/status/204", result: :ok}
    ]

    assert expected_result_state == ExecutionState.get_results()
  end

  test "Given a yaml steps when it has a failing step then an error is returned" do
    {result, _message} =
      "test/support/fixtures/worker/yaml/test_request_internal_error.yml"
      |> Parser.parse!()
      |> Executor.execute()

    assert :error === result

    expected_result_state = [
      %Result{
        action: "get",
        host: "https://localhost:5743/status/500",
        failed_assertions: %{status_code: %{expected: [200, 201, 202, 203, 204], received: 500}},
        result: :error
      }
    ]

    assert expected_result_state == ExecutionState.get_results()
  end

  test "Given a yaml with an expect code when a response returns the same code then an error is returned" do
    result =
      "test/support/fixtures/worker/yaml/test_status_code.yml"
      |> Parser.parse!()
      |> Executor.execute()

    assert :ok === result

    expected_result_state = [
      %Result{action: "get", host: "https://localhost:5743/status/423", result: :ok}
    ]

    assert expected_result_state == ExecutionState.get_results()
  end

  test "Given a yaml with an expect code when a response returns a different code then an error is returned" do
    {result, _message} =
      "test/support/fixtures/worker/yaml/test_status_code_error.yml"
      |> Parser.parse!()
      |> Executor.execute()

    assert :error === result

    expected_result_state = [
      %Result{
        action: "get",
        host: "https://localhost:5743/get",
        failed_assertions: %{status_code: %{expected: 400, received: 200}},
        result: :error
      }
    ]

    assert expected_result_state == ExecutionState.get_results()
  end

  test "Given a yaml when it contains an invalid host then an error is returned" do
    {result, _message} =
      "test/support/fixtures/worker/yaml/test_invalid_host.yml"
      |> Parser.parse!()
      |> Executor.execute()

    assert :error === result

    expected_result_state = [
      %Result{
        action: "get",
        host: "invalid_host",
        failed_assertions: %{error: "Invalid host"},
        result: :error
      }
    ]

    assert expected_result_state == ExecutionState.get_results()
  end

  test "Given a yaml with an header when the response does not return the header then an error is returned" do
    {result, _message} =
      "test/support/fixtures/worker/yaml/test_headers_error.yml"
      |> Parser.parse!()
      |> Executor.execute()

    assert :error === result

    expeted_header = %{headers: [%{header: "a_header", expected: "a_value", received: nil}]}

    expected_result_state = [
      %Result{
        action: "get",
        host: "https://localhost:5743/status/202",
        failed_assertions: expeted_header,
        result: :error
      }
    ]

    assert expected_result_state == ExecutionState.get_results()
  end

  test "Given a yaml with an expected header and status code when the response does not return none of them then an error is returned" do
    {result, _message} =
      "test/support/fixtures/worker/yaml/test_status_code_and_headers_error.yml"
      |> Parser.parse!()
      |> Executor.execute()

    assert :error === result

    expeted_header = %{headers: [%{header: "a_header", expected: "a_value", received: nil}]}
    expeted_status_code = %{status_code: %{expected: 523, received: 202}}
    expected_assertions = Map.merge(expeted_header, expeted_status_code)

    expected_result_state = [
      %Result{
        action: "get",
        host: "https://localhost:5743/status/202",
        failed_assertions: expected_assertions,
        result: :error
      }
    ]

    assert expected_result_state == ExecutionState.get_results()
  end

  describe "Given a yaml plan" do
    test "when a request takes more time than the configured timout then an error is returned" do
      assert {:error, _message} =
               "test/support/fixtures/worker/yaml/test_timeout_opt.yml"
               |> Parser.parse!()
               |> Executor.execute()

      expected_result_state = [
        %Result{
          action: "get",
          host: "http://httpbin.org/get",
          failed_assertions: %{error: :timeout},
          result: :error
        }
      ]

      assert expected_result_state == ExecutionState.get_results()
    end

    test "when the body is a string then the body string is sent in the request" do
      assert :ok =
               "test/support/fixtures/worker/yaml/test_body_string.yml"
               |> Parser.parse!()
               |> Executor.execute()

      expected_result_state = [
        %Result{
          action: "post",
          host: "https://localhost:5743/post",
          result: :ok
        }
      ]

      assert expected_result_state == ExecutionState.get_results()
    end

    test "when save a response and the var key is used in another request then the request sends the var value" do
      assert :ok =
               "test/support/fixtures/worker/yaml/test_save_from_response.yml"
               |> Parser.parse!()
               |> Executor.execute()

      expected_result_state = [
        %Result{
          action: "post",
          host: "https://localhost:5743/post",
          result: :ok
        },
        %Result{
          action: "get",
          host: "https://localhost:5743/headers",
          result: :ok
        }
      ]

      assert expected_result_state == ExecutionState.get_results()
    end
  end
end
