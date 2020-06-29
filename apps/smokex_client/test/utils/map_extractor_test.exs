defmodule SmokexClient.Utils.MapExtractorTest do
  use ExUnit.Case

  alias SmokexClient.Utils.MapExtractor
  alias SmokexClient.Step.Request.SaveFromResponse

  describe "Given a json path" do
    test "when the response contains the path then the value its returned" do
      {result, extracted_value} =
        MapExtractor.extract_variable_from_json_path(
          %SaveFromResponse{variable_name: "test_var", json_path: "test.nested"},
          %{"test" => %{"nested" => "nested_value"}}
        )

      assert :ok === result
      assert "nested_value" === extracted_value
    end

    test "when the path is deep and the response contains the path then the value its returned" do
      {result, extracted_value} =
        MapExtractor.extract_variable_from_json_path(
          %SaveFromResponse{
            variable_name: "test_var",
            json_path: "test.nested.another_nest.deep"
          },
          %{"test" => %{"nested" => %{"another_nest" => %{"deep" => "deep_value"}}}}
        )

      assert :ok === result
      assert "deep_value" === extracted_value
    end

    test "when the response does not contain the path then an error with a nil value its returned" do
      {result, extracted_value} =
        MapExtractor.extract_variable_from_json_path(
          %SaveFromResponse{variable_name: "test_var", json_path: "test.nested.inexistent"},
          %{"test" => %{"nested" => "nested_value"}}
        )

      assert :error === result
      assert nil === extracted_value
    end

    test "when the response is an empty map then an error with a nil value its returned" do
      {result, extracted_value} =
        MapExtractor.extract_variable_from_json_path(
          %SaveFromResponse{variable_name: "test_var", json_path: "test.nested.inexistent"},
          %{}
        )

      assert :error === result
      assert nil === extracted_value
    end
  end
end
