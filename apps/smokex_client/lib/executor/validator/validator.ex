defmodule SmokexClient.Validator do
  alias Smokex.Step.Request.Expect

  alias SmokexClient.Validator.StatusCode
  alias SmokexClient.Validator.Headers
  alias SmokexClient.Validator.Body

  @typedoc """
  Represents the validation result.

  ### Success validation

  If no errors are found and all the validation check pass, the validation
  process is a tuple containing the response body: `{:ok, response_body}`.

  ### Failed validations

  If errors were found, they will be represented with a triplet with the
  accumulated errors and a message: `{:error, map_with_assertions_failed,
  description_message}`.
  """
  @type validation_result :: {:ok, response_body} | {:error, map, String.t()}

  @type response_body :: map | String.t()

  @type expect_validation_result :: {:ok, term} | {:error, map, String.t()}

  @doc """
  Validates a response body with the given expectations.

  This functions iterates over all defined expectation and returns a
  `t:validation_result/0` containing whether if there were expectations failed
  or not.
  """
  @spec validate(Expect.t(), Tesla.Env.t()) :: validation_result
  def validate(%Expect{} = expected, %Tesla.Env{} = response) do
    %Tesla.Env{body: body, status: status_code, headers: headers} = response

    with status_code_result <- StatusCode.validate(expected, status_code),
         headers_result <- Headers.validate(expected, headers),
         body_result <- Body.validate(expected, body) do
      {:ok, body}
      |> add_validation_error(status_code_result)
      |> add_validation_error(headers_result)
      |> add_validation_error(body_result)
    end
  end

  #
  # Private functions
  #

  @spec add_validation_error(validation_result, expect_validation_result) :: validation_result
  defp add_validation_error(current_errors_result, validation_result) do
    case {current_errors_result, validation_result} do
      {_, {:ok, _}} ->
        current_errors_result

      {{:error, current_errors, _}, {:error, error_to_add, _}} ->
        {:error, Map.merge(current_errors, error_to_add), "Multiple assertion errors"}

      {{:ok, _}, {:error, error_to_add, message}} when is_map(error_to_add) ->
        {:error, error_to_add, message}
    end
  end
end
