defmodule SmokexClient.Validator.HTML do
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
        %Expect{html: html_expects},
        received_body
      ) do
    html_validations =
      html_expects
      |> Enum.map(&validate_html_path(&1, received_body))
      |> Enum.reject(&is_nil/1)

    %ValidationContext{validation_errors: html_validations ++ validation_errors}
  end

  def validate_html_path(%{path: css_path, expected: expected_value}, received_body) do
    with document <- Meeseeks.parse(received_body),
         css_selector <- Meeseeks.css(css_path),
         result when not is_nil(result) <- Meeseeks.one(document, css_selector),
         ^expected_value <- Meeseeks.own_text(result) do
      nil
    else
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
