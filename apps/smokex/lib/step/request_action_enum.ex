defmodule Smokex.Step.RequestActionEnum do
  @moduledoc """
  This module represents any supported request action.

  Currently only HTTP methods are supported as actions.
  """

  @http_actions [:get, :post, :patch, :put, :head, :delete, :options, :trace, :connect]

  use EctoEnum,
    type: :request_action,
    enums: @http_actions
end
