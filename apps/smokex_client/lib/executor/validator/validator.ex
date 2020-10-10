defmodule SmokexClient.Validator do
  alias Smokex.Step.Request.Expect

  alias SmokexClient.Validator.StatusCode
  alias SmokexClient.Validator.Headers
  alias SmokexClient.Validator.JSON
  alias SmokexClient.Validator.String, as: StringValidator
  alias SmokexClient.Validator.HTML
  alias SmokexClient.Validator.ValidationContext

  @typedoc """
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
  @spec validate(Expect.t(), Tesla.Env.t()) :: ValidationContext.t()
  def validate(%Expect{} = expected, %Tesla.Env{} = response) do
    %Tesla.Env{body: body, status: status_code, headers: headers} = response

    %ValidationContext{}
    |> StatusCode.validate(expected, status_code)
    |> Headers.validate(expected, headers)
    |> JSON.validate(expected, body)
    |> StringValidator.validate(expected, body)
    |> HTML.validate(expected, body)
  end
end
