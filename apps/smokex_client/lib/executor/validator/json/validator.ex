defmodule SmokexClient.Validator.JSON do
  alias Smokex.Step.Request.Expect
  alias SmokexClient.Validator.ValidationContext
  alias SmokexClient.Validator.Validation

  @spec validate(ValidationContext.t(), Expect.t(), String.t() | map) :: ValidationContext.t()
  def validate(%ValidationContext{} = validation_context, %Expect{json: nil}, _received_body),
    do: validation_context

  def validate(
        %ValidationContext{validation_errors: validation_errors} = validation_context,
        %Expect{json: expected_map},
        received_body
      )
      when is_binary(received_body) do
    with {:ok, response_map} <- Jason.decode(received_body) do
      do_validate(validation_context, expected_map, response_map)
    else
      _error ->
        %ValidationContext{
          validation_errors: [
            %Validation{type: :json, expected: expected_map, received: received_body}
            | validation_errors
          ]
        }
    end
  end

  def validate(
        %ValidationContext{} = validation_context,
        %Expect{json: expected_map},
        response_map
      )
      when is_map(response_map) do
    do_validate(validation_context, expected_map, response_map)
  end

  #
  # Private functions
  #

  @spec do_validate(ValidationContext.t(), map, map) :: ValidationContext.t()
  defp do_validate(
         %ValidationContext{validation_errors: validation_errors} = validation_context,
         expected_map,
         response_map
       ) do
    expected_map
    |> Map.to_list()
    |> Enum.all?(&(&1 in response_map))
    |> case do
      true ->
        validation_context

      false ->
        %ValidationContext{
          validation_errors: [
            %Validation{type: :json, expected: expected_map, received: response_map}
            | validation_errors
          ]
        }
    end
  end
end
