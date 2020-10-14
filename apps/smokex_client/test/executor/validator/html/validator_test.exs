defmodule SmokexClient.Validator.HTMLTest do
  use ExUnit.Case, async: true

  alias Smokex.Step.Request.Expect
  alias SmokexClient.Validator.HTML
  alias SmokexClient.Validator.ValidationContext

  describe "validate/3" do
    test "returns the given validation context when html expectations is empty" do
      validation_context = %ValidationContext{validation_errors: []}

      assert ^validation_context =
               HTML.validate(validation_context, %Expect{html: []}, "received body")

      assert ^validation_context =
               HTML.validate(validation_context, %Expect{html: nil}, "received body")
    end

    test "returns the validation context with no additional errors when html response fills all the expectations" do
      validation_context = %ValidationContext{validation_errors: []}
      expect = %Expect{html: [%{path: "span", equal: "a value"}]}

      assert ^validation_context =
               HTML.validate(validation_context, expect, """
               <html>
                 <body>
                   <span>a value</span>
                 </body>
               </html>
               """)
    end

    test "returns the validation context with the errors of the expectations not met by the HTML" do
      validation_context = %ValidationContext{validation_errors: []}

      expect = %Expect{
        html: [
          %{path: "span.class", equal: "a value"},
          %{path: "span#test", equal: "another value"},
          %{path: "span#test_2", equal: "another value"}
        ]
      }

      assert %ValidationContext{
               validation_errors: [
                 %SmokexClient.Validator.Validation{
                   expected: "a value",
                   name: "span.class",
                   received: "a values",
                   type: :html
                 },
                 %SmokexClient.Validator.Validation{
                   expected: "another value",
                   name: "span#test_2",
                   received: "a values",
                   type: :html
                 }
               ]
             } =
               HTML.validate(validation_context, expect, """
               <html>
                 <body>
                   <span class="class">a values</span>
                   <span id="test">another value</span>
                   <p>a values</p>
                   <span id="test_2">a values</span>
                 </body>
               </html>
               """)
    end
  end
end
