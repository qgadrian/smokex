defmodule Smokex.ResulstsTest do
  use ExUnit.Case, async: true
  use Smokex.DataCase

  import Smokex.TestSupport.Factories

  alias Smokex.Results
  alias Smokex.Results.HTTPRequestResult

  describe "has_failed?/1" do
    test "returns false if `failed_assertions` is blank" do
      refute Results.has_failed?(%HTTPRequestResult{failed_assertions: %{}})
      refute Results.has_failed?(%HTTPRequestResult{failed_assertions: nil})
      refute Results.has_failed?(%HTTPRequestResult{failed_assertions: []})
    end

    test "returns true if the result has `failed_assertions`" do
      assert Results.has_failed?(%HTTPRequestResult{failed_assertions: %{"field" => "failed"}})
    end
  end
end
