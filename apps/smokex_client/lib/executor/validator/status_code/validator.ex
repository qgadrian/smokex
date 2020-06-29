defmodule SmokexClient.Validator.StatusCode do
  alias SmokexClient.Step.Request.Expect

  alias SmokexClient.Printer.SmokeStep, as: Printer

  @sucess_status_codes [200, 201, 202, 203, 204]

  @spec validate(Expect.t(), non_neg_integer) :: tuple
  def validate(%Expect{} = expected, status_code) do
    case Map.get(expected, :status_code) do
      nil ->
        validate_response_status_code(status_code)

      expected_status_code ->
        validate_expected_status_code(expected_status_code, status_code)
    end
  end

  @spec validate_response_status_code(number) :: tuple
  defp validate_response_status_code(status_code) do
    if Enum.any?(@sucess_status_codes, &(&1 == status_code)) do
      Printer.print_validation(:sucess, "Received 20x status code")
      {:ok, status_code}
    else
      Printer.print_validation(:error, "Received #{status_code} status code")

      {:error, %{status_code: %{expected: @sucess_status_codes, received: status_code}},
       "Received non 20x status code"}
    end
  end

  @spec validate_expected_status_code(number, number) :: tuple
  defp validate_expected_status_code(expected_status_code, status_code) do
    if expected_status_code == status_code do
      Printer.print_validation(:sucess, "Received expected #{expected_status_code} status code")
      {:ok, status_code}
    else
      Printer.print_validation(
        :error,
        "Expected status code #{expected_status_code} but received #{status_code}"
      )

      {:error, %{status_code: %{expected: expected_status_code, received: status_code}},
       "Unexpected status code"}
    end
  end
end
