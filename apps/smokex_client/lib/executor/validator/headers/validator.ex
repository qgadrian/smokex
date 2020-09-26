defmodule SmokexClient.Validator.Headers do
  alias Smokex.Step.Request.Expect

  @spec validate(Expect.t(), list(tuple)) ::
          {:ok, term} | {:error, %{headers: list(map)}, String.t()}
  def validate(%Expect{} = expected, received_headers) do
    case Map.get(expected, :headers) do
      nil ->
        {:ok, "No headers expected"}

      expected_headers ->
        expected_headers
        |> get_headers_to_validate(received_headers)
        |> validate_expected_headers()
        |> group_validated_headers()
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

  @spec group_validated_headers(list(map)) :: {:ok, :headers} | list(map)
  defp group_validated_headers(headers_validation) do
    all_headers_valid = Enum.all?(headers_validation, fn {result, _header} -> result == :ok end)

    case all_headers_valid do
      true ->
        {:ok, :headers}

      false ->
        get_invalid_headers(headers_validation)
    end
  end

  @spec get_invalid_headers(list(map)) :: list(map)
  defp get_invalid_headers(headers_validation) do
    headers_validation
    |> Enum.filter(fn {result, _header} -> result == :error end)
    |> Enum.reduce([], fn {_result, header}, acc -> [header | acc] end)
  end
end
