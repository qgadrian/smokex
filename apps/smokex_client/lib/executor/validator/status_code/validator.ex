defmodule SmokexClient.Validator.StatusCode do
  alias Smokex.Step.Request.Expect

  @sucess_status_codes [200, 201, 202, 203, 204]

  @spec validate(Expect.t(), non_neg_integer) ::
          {:ok, non_neg_integer} | {:error, map, String.t()}
  def validate(%Expect{} = expected, status_code) do
    case Map.get(expected, :status_code) do
      nil ->
        validate_response_status_code(status_code)

      expected_status_code ->
        validate_expected_status_code(expected_status_code, status_code)
    end
  end

  #
  # Private functions
  #

  @spec validate_response_status_code(non_neg_integer) ::
          {:ok, non_neg_integer} | {:error, map, String.t()}
  defp validate_response_status_code(status_code) do
    if Enum.any?(@sucess_status_codes, &(&1 == status_code)) do
      {:ok, status_code}
    else
      {:error, %{status_code: %{expected: @sucess_status_codes, received: status_code}},
       "Received non 20x status code"}
    end
  end

  @spec validate_expected_status_code(non_neg_integer, non_neg_integer) ::
          {:ok, non_neg_integer} | {:error, map, String.t()}
  defp validate_expected_status_code(expected_status_code, status_code) do
    if expected_status_code == status_code do
      {:ok, status_code}
    else
      {:error, %{status_code: %{expected: expected_status_code, received: status_code}},
       "Unexpected status code"}
    end
  end
end
