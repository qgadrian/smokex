defmodule SmokexClient.Utils.MapExtractor do
  alias Smokex.Step.Request.SaveFromResponse

  @spec extract_variable_from_json_path(SaveFromResponse.t(), map) :: {atom, String.t()}
  def extract_variable_from_json_path(%SaveFromResponse{} = save_from_response, json_response) do
    json_path = String.split(save_from_response.json_path, ".")

    json_path
    |> extract_variable(json_response)
    |> wrap_extracted_variable_in_result()
  end

  @spec extract_variable(list(String.t()), map) :: String.t() | nil
  defp extract_variable(json_path, json_response) do
    Enum.reduce(json_path, json_response, fn key, json_response_location ->
      case json_response_location do
        nil -> nil
        _ when is_map(json_response_location) -> Map.get(json_response_location, key)
        _ -> nil
      end
    end)
  end

  @spec wrap_extracted_variable_in_result(String.t() | nil) :: {:ok, String.t()} | {:error, nil}
  defp wrap_extracted_variable_in_result(json_path_value) do
    case json_path_value do
      nil -> {:error, nil}
      value -> {:ok, value}
    end
  end
end
