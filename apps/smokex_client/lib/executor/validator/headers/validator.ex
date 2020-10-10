defmodule SmokexClient.Validator.Headers do
  alias Smokex.Step.Request.Expect
  alias SmokexClient.Validator.ValidationContext
  alias SmokexClient.Validator.Validation

  @spec validate(ValidationContext.t(), Expect.t(), list(tuple)) :: ValidationContext.t()
  def validate(
        %ValidationContext{} = validation_context,
        %Expect{headers: nil},
        _received_headers
      ),
      do: validation_context

  def validate(
        %ValidationContext{} = validation_context,
        %Expect{headers: expected_headers},
        received_headers
      ) do
    expected_headers
    |> get_headers_to_validate(received_headers)
    |> validate_expected_headers()
    |> add_validations(validation_context)
  end

  #
  # Private functions
  #

  @spec get_headers_to_validate(map, list(tuple)) :: list(map)
  defp get_headers_to_validate(expected_headers, headers) do
    response_headers =
      Enum.reduce(headers, %{}, fn {header, value}, acc ->
        Map.put(acc, header, value)
      end)

    Enum.reduce(expected_headers, [], fn {header, value}, acc ->
      [%{header: header, expected: value, received: Map.get(response_headers, header)} | acc]
    end)
  end

  @spec validate_expected_headers(list(map)) :: list(Validation.t())
  defp validate_expected_headers(headers_to_validate) do
    Enum.reduce(headers_to_validate, [], fn header_to_validate, validations ->
      header_name = Map.get(header_to_validate, :header)
      expected = Map.get(header_to_validate, :expected)
      received = Map.get(header_to_validate, :received)

      if received == expected do
        validations
      else
        [
          %Validation{
            type: :header,
            name: header_name,
            expected: expected,
            received: received
          }
          | validations
        ]
      end
    end)
  end

  @spec add_validations(list(Validation.t()), ValidationContext.t()) :: ValidationContext.t()
  defp add_validations(
         header_validations,
         %ValidationContext{validation_errors: validation_errors}
       ) do
    %ValidationContext{validation_errors: header_validations ++ validation_errors}
  end
end
