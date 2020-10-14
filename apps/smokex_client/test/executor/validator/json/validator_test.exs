defmodule SmokexClient.Validator.JSONTest do
  use ExUnit.Case, async: true

  alias Smokex.Step.Request.Expect
  alias SmokexClient.Validator.JSON
  alias SmokexClient.Validator.ValidationContext

  describe "validate/3" do
    test "returns the given validation context when json expectations is empty" do
      validation_context = %ValidationContext{validation_errors: []}

      assert ^validation_context =
               JSON.validate(validation_context, %Expect{json: nil}, "received body")
    end

    test "returns the validation context with no additional errors when html response fills all the expectations" do
      validation_context = %ValidationContext{validation_errors: []}
      expect = %Expect{json: %{"key" => "is present"}}

      assert ^validation_context =
               JSON.validate(validation_context, expect, "{\"key\": \"is present\"}")
    end

    test "returns the validation context with the errors of the expectations not met by the JSON" do
      validation_context = %ValidationContext{validation_errors: []}

      expect = %Expect{json: %{"key" => "other"}}

      assert %ValidationContext{
               validation_errors: [
                 %SmokexClient.Validator.Validation{
                   expected: %{"key" => "other"},
                   name: nil,
                   received: %{"key" => "is present"},
                   type: :json
                 }
               ]
             } = JSON.validate(validation_context, expect, "{\"key\": \"is present\"}")
    end
  end
end
