defmodule SmokexClient.Test.Parsers.Yaml do
  use ExUnit.Case

  @moduletag :parser

  alias SmokexClient.Step.Request
  alias SmokexClient.Step.Request.Expect
  alias SmokexClient.Step.Request.SaveFromResponse

  alias SmokexClient.Parsers.Yaml.Parser

  test "When a yaml file path doesn't exists then an error is returned" do
    {result, _message} = Parser.parse("test/support/fixtures/parser/yaml/invalid.yml")

    assert :error === result
  end

  test "Given a non existen yaml file when do a bang parse then an exception is thrown" do
    error_result = Parser.parse("an_invalid.yml")

    assert error_result === catch_throw(Parser.parse!("an_invalid.yml"))
  end

  test "Given a yml run plan with multiple and different actions when its parsed then a list with with the actions is returned" do
    result_response = Parser.parse("test/support/fixtures/parser/yaml/test_multiple_requests.yml")

    expected_yaml_data = [
      %Request{action: "get", host: "test_2_host_1"},
      %Request{action: "get", host: "test_2_host_2"},
      %Request{action: "post", host: "test_2_host_3"},
      %Request{action: "get", host: "test_2_host_4"},
      %Request{action: "post", host: "test_2_host_5"},
      %Request{action: "post", host: "test_2_host_6"},
      %Request{action: "patch", host: "test_2_host_7"}
    ]

    assert {:ok, expected_yaml_data} === result_response
  end

  test "Given a yml run plan with params when its parsed then a list with the params is returned" do
    result_response = Parser.parse("test/support/fixtures/parser/yaml/test_parse_params.yml")

    expected_yaml_data = [
      %Request{action: "get", host: "test_3_host_1", query: %{"param_1" => "param_1"}},
      %Request{action: "get", host: "test_3_host_2"},
      %Request{
        action: "post",
        host: "test_3_host_3",
        body: %{"param_1" => "param_1", "param_2" => "param_2"}
      }
    ]

    assert {:ok, expected_yaml_data} === result_response
  end

  test "Given a yml run plan with headers when its parsed then a list with the headers is returned" do
    result_response = Parser.parse("test/support/fixtures/parser/yaml/test_headers.yml")

    expected_yaml_data = [
      %Request{
        action: "get",
        host: "test_host",
        query: %{"param_1" => "param_1"},
        expect: %Expect{status_code: 200},
        headers: %{"header_1" => "header_1", "header_2" => "header_2"}
      }
    ]

    assert {:ok, expected_yaml_data} === result_response
  end

  test "Given a yml run plan with expect body when its parsed then the expect result with the expected body is returned" do
    result_response = Parser.parse("test/support/fixtures/parser/yaml/test_expect_body.yml")

    expected_yaml_data = [
      %Request{
        action: "get",
        host: "test_host",
        query: %{"param_1" => "param_1"},
        expect: %Expect{
          status_code: 200,
          body: "an expected body"
        }
      }
    ]

    assert {:ok, expected_yaml_data} === result_response
  end

  test "Given a yml run plan with expect status code when its parsed then a list with the expect result is returned" do
    result_response =
      Parser.parse("test/support/fixtures/parser/yaml/test_expect_status_code.yml")

    expected_yaml_data = [
      %Request{
        action: "get",
        host: "test_host",
        query: %{"param_1" => "param_1"},
        expect: %Expect{status_code: 200}
      }
    ]

    assert {:ok, expected_yaml_data} === result_response
  end

  test "Given a yml run plan with expect headers when its parsed then a list with the expected headers is returned" do
    result_response = Parser.parse("test/support/fixtures/parser/yaml/test_expect_headers.yml")

    expected_yaml_data = [
      %Request{
        action: "get",
        host: "test_host",
        query: %{"param_1" => "param_1"},
        expect: %Expect{
          status_code: 200,
          headers: %{"header_1" => "value_1", "header_2" => "value_2"}
        }
      }
    ]

    assert {:ok, expected_yaml_data} === result_response
  end

  describe "Given a yml plan with save to variable" do
    test "when the response contains the json path then the value its saved to the variable" do
      result_response = Parser.parse("test/support/fixtures/parser/yaml/save_to_variable.yml")

      expected_yaml_data = [
        %Request{
          action: "post",
          host: "https://httpbin.org/get",
          body: %{
            "test" => %{
              "value" => "param_1",
              "another_value" => %{"another_value_child" => "another_value_child_value"}
            }
          },
          save_from_response: [
            %SaveFromResponse{variable_name: "save_test", json_path: "test.value"},
            %SaveFromResponse{
              variable_name: "save_another_value",
              json_path: "test.another_value.another_value_child"
            }
          ]
        }
      ]

      assert {:ok, expected_yaml_data} === result_response
    end
  end

  describe "Given a yaml plan" do
    test "when a request has opts then the parsed steps have the opts" do
      result_response =
        Parser.parse("test/support/fixtures/parser/yaml/test_parse_request_opts.yml")

      expected_yaml_data = [
        %Request{
          action: "get",
          host: "http://httpbing.org/",
          query: %{"query_key" => "query_value"},
          opts: [timeout: 5000]
        }
      ]

      assert {:ok, expected_yaml_data} === result_response
    end

    test "when the body is a string then the step has the body value" do
      result_response =
        Parser.parse("test/support/fixtures/parser/yaml/test_parse_body_string.yml")

      expected_yaml_data = [
        %Request{
          action: "get",
          host: "http://httpbing.org/",
          body: "this is a body string"
        }
      ]

      assert {:ok, expected_yaml_data} === result_response
    end
  end
end
