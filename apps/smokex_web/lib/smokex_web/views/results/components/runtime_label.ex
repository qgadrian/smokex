defmodule SmokexWeb.Results.Components.RuntimeLabel do
  use SmokexWeb, :view

  alias Smokex.Result
  alias Smokex.Results.HTTPResponse

  @default_class "is-size-7 pl-1"

  @spec new(Result.t()) :: term
  def new(%Result{updated_at: finished_at, inserted_at: started_at})
      when is_nil(finished_at) or is_nil(started_at) do
    content_tag(:span, "...", class: @default_class)
  end

  def new(%Result{response: %HTTPResponse{} = response}) do
    duration =
      response.finished_at
      |> Timex.diff(response.started_at, :milliseconds)
      |> Timex.Duration.from_microseconds()
      |> Timex.format_duration(:humanized)

    content_tag(:span, duration, class: @default_class)
  end
end
