defmodule SmokexClient.Validator.Body do
  alias Smokex.Step.Request.Expect

  alias SmokexClient.Printer.SmokeStep, as: Printer

  defstruct errors: []

  @spec validate(Expect.t(), String.t()) :: tuple
  def validate(%Expect{} = expected, received_body) do
    case expected.body do
      nil ->
        {:ok, :skipped}

      expected_body ->
        validate_expected_body(expected_body, received_body)
    end
  end

  @spec validate_expected_body(String.t(), String.t()) :: tuple
  defp validate_expected_body(expected_body, received_body) when is_binary(expected_body) do
    if expected_body == received_body do
      {:ok, received_body}
    else
      Printer.print_validation(:error, "Received body is not same as expected body")

      {
        :error,
        %{body: %{expected: expected_body, received: received_body}},
        "\nExpected body:\n#{expected_body}\nReceived:\n#{received_body}\n"
      }
    end
  end

  @spec validate_expected_body(map, String.t()) :: tuple
  defp validate_expected_body(expected_body, received_body) do
    with {:ok, parsed_received_body} <- Jason.decode(received_body) do
      if Map.equal?(expected_body, parsed_received_body) do
        {:ok, received_body}
      else
        Printer.print_validation(:error, "Received body is not same as expected body")

        {
          :error,
          %{body: %{expected: expected_body, received: received_body}},
          "\nExpected body:\n#{Jason.encode!(expected_body)}\nReceived:\n#{inspect(received_body)}\n"
        }
      end
    else
      _ ->
        Printer.print_validation(:error, "Received body is not same as expected body")

        {
          :error,
          %{body: %{expected: expected_body, received: received_body}},
          "\nExpected body:\n#{inspect(expected_body)}\nReceived:\n#{received_body}\n"
        }
    end
  end
end
