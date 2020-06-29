defmodule Smokex.Step.RequestResultEnum do
  @moduledoc """
  This module represents result from a request execution.
  """

  use EctoEnum,
    type: :request_result,
    enums: [:ok, :error]
end
