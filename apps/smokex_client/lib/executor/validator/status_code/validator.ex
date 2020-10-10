defmodule SmokexClient.Validator.StatusCode do
  alias Smokex.Step.Request.Expect
  alias SmokexClient.Validator.ValidationContext
  alias SmokexClient.Validator.Validation

  @sucess_status_codes [200, 201, 202, 203, 204]

  @spec validate(ValidationContext.t(), Expect.t(), status_code :: non_neg_integer) ::
          ValidationContext.t()
  def validate(%ValidationContext{} = validation_context, %Expect{status_code: nil}, status_code)
      when is_number(status_code) do
    updated_validation_errors =
      validate_default_expected_status_code(validation_context, status_code)

    %ValidationContext{validation_errors: updated_validation_errors}
  end

  def validate(
        %ValidationContext{} = validation_context,
        %Expect{status_code: expected_status_code},
        status_code
      )
      when is_number(status_code) do
    updated_validation_errors =
      validate_expected_status_code(validation_context, expected_status_code, status_code)

    %ValidationContext{validation_errors: updated_validation_errors}
  end

  #
  # Private functions
  #

  @spec validate_default_expected_status_code(
          ValidationContext.t(),
          status_code :: non_neg_integer
        ) :: list(Validation.t())
  defp validate_default_expected_status_code(
         %ValidationContext{validation_errors: validation_errors},
         status_code
       ) do
    if status_code < 300 do
      validation_errors
    else
      [
        %Validation{type: :status_code, expected: @sucess_status_codes, received: status_code}
        | validation_errors
      ]
    end
  end

  @spec validate_expected_status_code(
          ValidationContext.t(),
          expected_status_code :: non_neg_integer,
          status_code :: non_neg_integer
        ) :: list(Validation.t())
  defp validate_expected_status_code(
         %ValidationContext{validation_errors: validation_errors},
         expected_status_code,
         status_code
       ) do
    if expected_status_code == status_code do
      validation_errors
    else
      [
        %Validation{type: :status_code, expected: expected_status_code, received: status_code}
        | validation_errors
      ]
    end
  end
end
