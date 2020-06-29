defmodule SmokexClient.Validator do
  alias Smokex.Step.Request.Expect

  alias SmokexClient.Validator.StatusCode
  alias SmokexClient.Validator.Headers
  alias SmokexClient.Validator.Body

  @default_validation_errors %{}

  @type validation_error_acc :: {:error, map, String.t()} | any
  @type validation_result :: {:ok, any} | {:error, any, String.t()}

  @spec validate(Expect.t(), HTTPoison.Response.t()) :: validation_result
  def validate(%Expect{} = expected, response) do
    %HTTPoison.Response{body: body, status_code: status_code, headers: headers} = response

    with status_code_result <- StatusCode.validate(expected, status_code),
         headers_result <- Headers.validate(expected, headers),
         body_result <- Body.validate(expected, body) do
      @default_validation_errors
      |> add_validation_error(status_code_result)
      |> add_validation_error(headers_result)
      |> add_validation_error(body_result)
      |> return_validation_result(body)
    end
  end

  @spec add_validation_error(validation_error_acc, validation_result) :: validation_error_acc
  defp add_validation_error(acc, validation_result) do
    case {acc, validation_result} do
      {_, {:ok, _}} ->
        acc

      {{:error, error_infos, _}, {:error, error_info, _}} ->
        {:error, Map.merge(error_infos, error_info), "Multiple assertion errors"}

      {_, {:error, error_info, message}} ->
        {:error, error_info, message}
    end
  end

  @spec return_validation_result(validation_error_acc, String.t()) :: validation_result
  defp return_validation_result(validation_errors, response_body) do
    case validation_errors do
      @default_validation_errors ->
        {:ok, parse_json_response_body(response_body)}

      _ ->
        validation_errors
    end
  end

  @spec parse_json_response_body(String.t()) :: map | nil
  defp parse_json_response_body(body) do
    with {:ok, parsed_body} <- Jason.decode(body) do
      parsed_body
    else
      _ ->
        body
    end
  end
end
