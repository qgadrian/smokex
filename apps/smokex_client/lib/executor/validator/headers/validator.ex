defmodule SmokexClient.Validator.Headers do
  alias SmokexClient.Step.Request.Expect

  alias SmokexClient.Printer.SmokeStep, as: Printer

  @spec validate(Expect.t(), list(tuple)) ::
          {:ok, :headers} | {:error, %{headers: list(map)}, String.t()}
  def validate(%Expect{} = expected, headers) do
    case Map.get(expected, :headers) do
      nil ->
        {:ok, "No headers expected"}

      expected_headers ->
        expected_headers
        |> get_headers_to_validate(headers)
        |> validate_expected_headers()
        |> print_headers_validation()
        |> build_validation_result()
    end
  end

  @spec build_validation_result({:ok, :headers} | list(map)) ::
          {:ok, :headers} | {:error, %{headers: list(map)}, String.t()}
  defp build_validation_result(headers_validation_info) do
    case headers_validation_info do
      {:ok, :headers} ->
        {:ok, :headers}

      invalid_headers ->
        {:error, %{headers: invalid_headers}, "Invalid headers"}
    end
  end

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

  @spec validate_expected_headers(list(map)) :: list(any)
  defp validate_expected_headers(headers_to_validate) do
    Enum.map(headers_to_validate, fn header_to_validate ->
      header = Map.get(header_to_validate, :header)
      expected = Map.get(header_to_validate, :expected)
      received = Map.get(header_to_validate, :received)

      if received == expected do
        {:ok, header}
      else
        {:error, header_to_validate}
      end
    end)
  end

  @spec print_headers_validation(list(map)) :: {:ok, :headers} | list(map)
  defp print_headers_validation(headers_validation) do
    all_headers_valid = Enum.all?(headers_validation, fn {result, _header} -> result == :ok end)

    case all_headers_valid do
      true ->
        Printer.print_validation(:sucess, "All headers present")
        {:ok, :headers}

      false ->
        headers_validation
        |> get_invalid_headers()
        |> print_invalid_headers()
    end
  end

  @spec print_invalid_headers(list(map)) :: list(map)
  defp print_invalid_headers(invalid_headers) do
    Enum.each(invalid_headers, fn %{header: header, expected: expected, received: received} ->
      case received do
        nil ->
          Printer.print_validation(
            false,
            "Expected header #{header} to be '#{expected}' but was not present"
          )

        received_value ->
          Printer.print_validation(
            false,
            "Expected header #{header} to be '#{expected}' but received '#{received_value}'"
          )
      end
    end)

    invalid_headers
  end

  @spec get_invalid_headers(list(map)) :: list(map)
  defp get_invalid_headers(headers_validation) do
    headers_validation
    |> Enum.filter(fn {result, _header} -> result == :error end)
    |> Enum.reduce([], fn {_result, header}, acc -> [header | acc] end)
  end
end
