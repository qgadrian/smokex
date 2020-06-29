defmodule SmokexClient.Result do
  defstruct [
    :action,
    :host,
    :failed_assertions,
    :result
  ]
end
