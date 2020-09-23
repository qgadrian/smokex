defmodule SmokexClient.Test.Validator do
  use ExUnit.Case

  @moduletag :validator

  alias Smokex.Step.Request.Expect

  alias SmokexClient.Validator

  test "Given no expected response when the status code is 20x then an ok is returned" do
    mock_response = %Tesla.Env{status: 200, body: ""}
    mock_expect = %Expect{}

    {result, _other} = Validator.validate(mock_expect, mock_response)

    assert :ok === result
  end

  test "Given no expected response when the status code is not 20x then an error is returned" do
    mock_response = %Tesla.Env{status: 400, body: ""}
    mock_expect = %Expect{}

    {result, %{status_code: %{received: received}}, _message} =
      Validator.validate(mock_expect, mock_response)

    assert :error === result
    assert 400 === received
  end

  test "Given expected status code when the response status code is equal then an ok is returned" do
    mock_response = %Tesla.Env{status: 323, body: ""}
    mock_expect = %Expect{status_code: 323}

    {result, _other} = Validator.validate(mock_expect, mock_response)

    assert :ok === result
  end

  test "Given expected status code when the response status code is different then an error is returned" do
    mock_response = %Tesla.Env{status: 400, body: ""}
    mock_expect = %Expect{status_code: 300}

    {result, %{status_code: %{expected: expected, received: received}}, _message} =
      Validator.validate(mock_expect, mock_response)

    assert :error === result
    assert 300 === expected
    assert 400 === received
  end

  test "Given expected headers when the response headers include them then an ok is returned" do
    mock_headers = [{"header_1", "value_1"}, {"header_2", "value_2"}]
    mock_response = %Tesla.Env{status: 200, headers: mock_headers, body: ""}
    mock_expect = %Expect{headers: %{"header_1" => "value_1", "header_2" => "value_2"}}

    {result, _} = Validator.validate(mock_expect, mock_response)

    assert :ok === result
  end

  test "Given expected headers when the response headers doesnt include them then an error is returned" do
    mock_response = %Tesla.Env{status: 200, headers: [], body: ""}
    mock_expect = %Expect{headers: %{"header_1" => "value_1", "header_2" => "value_2"}}

    {result,
     %{
       headers: [
         %{header: header_1, expected: expected_1, received: received_1},
         %{header: header_2, expected: expected_2, received: received_2}
       ]
     }, _message} = Validator.validate(mock_expect, mock_response)

    assert :error === result
    assert "header_1" === header_1
    assert "value_1" === expected_1
    assert nil === received_1
    assert "header_2" === header_2
    assert "value_2" === expected_2
    assert nil === received_2
  end

  test "Given expected header when the response header has different value then an error is returned" do
    mock_headers = [{"header_1", "value_1"}, {"header_2", "value_23"}]
    mock_response = %Tesla.Env{status: 200, headers: mock_headers, body: ""}
    mock_expect = %Expect{headers: %{"header_1" => "value_1", "header_2" => "value_2"}}

    {result, %{headers: [%{header: header, expected: expected, received: received}]}, _message} =
      Validator.validate(mock_expect, mock_response)

    assert :error === result
    assert "header_2" === header
    assert "value_2" === expected
    assert "value_23" === received
  end

  test "Given expected body when equals the received body then an ok is returned" do
    mock_body = "this is a body"

    mock_response = %Tesla.Env{status: 200, body: mock_body}
    mock_expect = %Expect{body: mock_body}

    assert {:ok, _} = Validator.validate(mock_expect, mock_response)
  end

  test "Given expected body when the response body has different value then an error is returned" do
    mock_expected_body = "this is a body"
    mock_received_body = "this is a different body"

    mock_response = %Tesla.Env{status: 200, body: mock_received_body}
    mock_expect = %Expect{body: mock_expected_body}

    {result, %{body: %{expected: expected_body, received: received_body}}, _message} =
      Validator.validate(mock_expect, mock_response)

    assert :error === result
    assert expected_body === mock_expected_body
    assert received_body === mock_received_body
  end
end
