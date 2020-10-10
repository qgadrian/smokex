defmodule SmokexClient.Test.Validator do
  use ExUnit.Case

  @moduletag :validator

  alias Smokex.Step.Request.Expect
  alias SmokexClient.Validator
  alias SmokexClient.Validator.ValidationContext
  alias SmokexClient.Validator.Validation

  test "Given no expected response when the status code is 20x then an ok is returned" do
    mock_response = %Tesla.Env{status: 200, body: ""}
    mock_expect = %Expect{}

    assert %ValidationContext{validation_errors: []} =
             Validator.validate(mock_expect, mock_response)
  end

  test "Given no expected response when the status code is not 20x then an error is returned" do
    mock_response = %Tesla.Env{status: 400, body: ""}
    mock_expect = %Expect{}

    assert %ValidationContext{
             validation_errors: [
               %Validation{type: :status_code, received: 400, expected: [200, 201, 202, 203, 204]}
             ]
           } = Validator.validate(mock_expect, mock_response)
  end

  test "Given expected status code when the response status code is equal then an ok is returned" do
    mock_response = %Tesla.Env{status: 323, body: ""}
    mock_expect = %Expect{status_code: 323}

    assert %ValidationContext{validation_errors: []} =
             Validator.validate(mock_expect, mock_response)
  end

  test "Given expected status code when the response status code is different then an error is returned" do
    mock_response = %Tesla.Env{status: 400, body: ""}
    mock_expect = %Expect{status_code: 300}

    assert %ValidationContext{
             validation_errors: [
               %Validation{type: :status_code, received: 400, expected: 300}
             ]
           } = Validator.validate(mock_expect, mock_response)
  end

  test "Given expected headers when the response headers include them then an ok is returned" do
    mock_headers = [{"header_1", "value_1"}, {"header_2", "value_2"}]
    mock_response = %Tesla.Env{status: 200, headers: mock_headers, body: ""}
    mock_expect = %Expect{headers: %{"header_1" => "value_1", "header_2" => "value_2"}}

    assert %ValidationContext{validation_errors: []} =
             Validator.validate(mock_expect, mock_response)
  end

  test "Given expected headers when the response headers doesnt include them then an error is returned" do
    mock_response = %Tesla.Env{status: 200, headers: [], body: ""}
    mock_expect = %Expect{headers: %{"header_1" => "value_1", "header_2" => "value_2"}}

    assert %ValidationContext{
             validation_errors: [
               %Validation{type: :header, name: "header_1", received: nil, expected: "value_1"},
               %Validation{type: :header, name: "header_2", received: nil, expected: "value_2"}
             ]
           } = Validator.validate(mock_expect, mock_response)
  end

  test "Given expected header when the response header has different value then an error is returned" do
    mock_headers = [{"header_1", "value_1"}, {"header_2", "value_23"}]
    mock_response = %Tesla.Env{status: 200, headers: mock_headers, body: ""}
    mock_expect = %Expect{headers: %{"header_1" => "value_1", "header_2" => "value_2"}}

    assert %ValidationContext{
             validation_errors: [
               %Validation{
                 type: :header,
                 name: "header_2",
                 received: "value_23",
                 expected: "value_2"
               }
             ]
           } = Validator.validate(mock_expect, mock_response)
  end

  test "Given expected body when equals the received body then an ok is returned" do
    mock_body = "this is a body"

    mock_response = %Tesla.Env{status: 200, body: mock_body}
    mock_expect = %Expect{string: mock_body}

    assert %ValidationContext{validation_errors: []} =
             Validator.validate(mock_expect, mock_response)
  end

  test "Given expected body when the response body has different value then an error is returned" do
    mock_expected_body = "this is a body"
    mock_received_body = "this is a different body"

    mock_response = %Tesla.Env{status: 200, body: mock_received_body}
    mock_expect = %Expect{string: mock_expected_body}

    assert %ValidationContext{
             validation_errors: [
               %Validation{
                 type: :string,
                 received: mock_received_body,
                 expected: mock_expected_body
               }
             ]
           } = Validator.validate(mock_expect, mock_response)
  end
end
