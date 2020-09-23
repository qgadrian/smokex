defmodule SmokexWeb.Results.Components.TimeAgoLabel do
  use SmokexWeb, :view

  alias Smokex.Result

  @spec new(Result.t()) :: term
  def new(%Result{inserted_at: nil}) do
    content_tag('time-ago', "not started", class: "no-wrap is-size-7 pl-1 is-italic")
  end

  def new(result) do
    content_tag('time-ago', Timex.from_now(result.inserted_at), class: "no-wrap is-size-7 pl-1")
  end
end
