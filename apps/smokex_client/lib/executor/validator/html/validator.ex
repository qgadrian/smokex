defmodule SmokexClient.Validator.HTML do
  @moduledoc """
  Module that validates HTML expectation against an HTML response.

  The HTML expectation use [CSS path
  selectors](https://www.w3schools.com/cssref/css_selectors.asp) to validate
  the text content.
  """

  alias Smokex.Step.Request.Expect
  alias SmokexClient.Validator.ValidationContext
  alias SmokexClient.Validator.Validation

  @spec validate(ValidationContext.t(), Expect.t(), String.t()) :: ValidationContext.t()
  def validate(%ValidationContext{} = validation_context, %Expect{html: []}, _received_body),
    do: validation_context

  def validate(%ValidationContext{} = validation_context, %Expect{html: nil}, _received_body),
    do: validation_context

  def validate(
        %ValidationContext{validation_errors: validation_errors},
        %Expect{},
        ""
      ) do
    %ValidationContext{
      validation_errors: [
        %Validation{
          type: :html,
          name: "response body",
          expected: "a valid HTML",
          received: "invalid HTML"
        }
        | validation_errors
      ]
    }
  end

  def validate(
        %ValidationContext{validation_errors: validation_errors},
        %Expect{html: html_expects},
        received_body
      ) do
    html_validations =
      html_expects
      |> Enum.map(&validate_html_path(&1, received_body))
      |> Enum.reject(&is_nil/1)

    %ValidationContext{validation_errors: html_validations ++ validation_errors}
  end

  def validate_html_path(%{path: css_path, equal: expected_value}, received_body) do
    with {:ok, document} <- Floki.parse_document(received_body),
         result when not is_nil(result) <- Floki.find(document, css_path),
         ^expected_value <- Floki.text(result) do
      nil
    else
      {:error, _reason} ->
        %Validation{
          type: :html,
          name: css_path,
          expected: expected_value,
          received: "invalid HTML"
        }

      unexpected_value ->
        %Validation{
          type: :html,
          name: css_path,
          expected: expected_value,
          received: unexpected_value
        }
    end
  end
end
