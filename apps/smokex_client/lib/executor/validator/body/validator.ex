defmodule SmokexClient.Validator.Body do
  alias Smokex.Step.Request.Expect

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

  #
  # Private functions
  #

  @spec validate_expected_body(map | String.t(), map | String.t()) :: tuple
  defp validate_expected_body(expected_body, received_body)
       when is_binary(expected_body) and is_map(received_body) do
    if expected_body == Jason.encode!(received_body) do
      {:ok, received_body}
    else
      {
        :error,
        %{body: %{expected: expected_body, received: received_body}},
        "\nExpected body:\n#{expected_body}\nReceived:\n#{inspect(received_body)}\n"
      }
    end
  end

  defp validate_expected_body(expected_body, received_body)
       when is_binary(expected_body) and is_binary(received_body) do
    if expected_body == received_body do
      {:ok, received_body}
    else
      {
        :error,
        %{body: %{expected: expected_body, received: received_body}},
        "\nExpected body:\n#{expected_body}\nReceived:\n#{received_body}\n"
      }
    end
  end

  defp validate_expected_body(expected_body, received_body)
       when is_map(expected_body) and is_map(received_body) do
    expected_body
    |> Map.to_list()
    |> Enum.all?(&(&1 in received_body))
    |> case do
      true ->
        {:ok, received_body}

      false ->
        {
          :error,
          %{body: %{expected: expected_body, received: received_body}},
          "\nExpected body:\n#{inspect(expected_body)}\nReceived:\n#{inspect(received_body)}\n"
        }
    end
  end

  defp validate_expected_body(expected_body, received_body)
       when is_map(expected_body) and is_binary(received_body) do
    case Jason.decode(received_body) do
      {:ok, received_body} ->
        expected_body
        |> Map.to_list()
        |> Enum.all?(&(&1 in received_body))
        |> case do
          true ->
            {:ok, received_body}

          false ->
            {
              :error,
              %{body: %{expected: expected_body, received: received_body}},
              "\nExpected body:\n#{inspect(expected_body)}\nReceived:\n#{inspect(received_body)}\n"
            }
        end

      {:error, _reason} ->
        {
          :error,
          %{body: %{expected: expected_body, received: received_body}},
          "\nWrong body:\n#{inspect(expected_body)}\nReceived:\n#{inspect(received_body)}\n"
        }
    end
  end

  defp validate_expected_body(expected_body, received_body) do
    {
      :error,
      %{body: %{expected: expected_body, received: received_body}},
      "\nExpected body:\n#{inspect(expected_body)}\nReceived:\n#{inspect(received_body)}\n"
    }
  end
end
