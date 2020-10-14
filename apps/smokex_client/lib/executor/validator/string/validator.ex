defmodule SmokexClient.Validator.String do
  alias Smokex.Step.Request.Expect
  alias SmokexClient.Validator.ValidationContext
  alias SmokexClient.Validator.Validation

  @spec validate(ValidationContext.t(), Expect.t(), String.t()) :: ValidationContext.t()
  def validate(%ValidationContext{} = validation_context, %Expect{string: nil}, _received_body),
    do: validation_context

  def validate(
        %ValidationContext{validation_errors: validation_errors} = validation_context,
        %Expect{string: expected_string},
        received_string
      )
      when is_binary(received_string) do
    if received_string =~ expected_string do
      validation_context
    else
      %ValidationContext{
        validation_errors: [
          %Validation{type: :string, expected: expected_string, received: received_string}
          | validation_errors
        ]
      }
    end
  end
end
