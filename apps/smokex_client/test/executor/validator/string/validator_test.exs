defmodule SmokexClient.Validator.StringTest do
  use ExUnit.Case, async: true

  alias Smokex.Step.Request.Expect
  alias SmokexClient.Validator.String
  alias SmokexClient.Validator.ValidationContext

  describe "validate/3" do
    test "returns the given validation context when string expectations is empty" do
      validation_context = %ValidationContext{validation_errors: []}

      assert ^validation_context =
               String.validate(validation_context, %Expect{string: nil}, "received body")

      assert ^validation_context =
               String.validate(validation_context, %Expect{string: ""}, "received body")
    end

    test "returns the validation context with no additional errors when html response contains the expected string" do
      validation_context = %ValidationContext{validation_errors: []}
      expect = %Expect{string: "body"}

      assert ^validation_context = String.validate(validation_context, expect, "response body")
    end

    test "returns the validation context with the errors of the expectations not met by the string" do
      validation_context = %ValidationContext{validation_errors: []}

      expect = %Expect{string: "other"}

      assert %ValidationContext{
               validation_errors: [
                 %SmokexClient.Validator.Validation{
                   expected: "other",
                   name: nil,
                   received: "response body",
                   type: :string
                 }
               ]
             } = String.validate(validation_context, expect, "response body")
    end
  end
end
