defmodule SmokexWeb.Results.Components.RuntimeLabel do
  use SmokexWeb, :view

  alias Smokex.Results.HTTPRequestResult
  alias Smokex.Results.HTTPResponse

  @default_class "is-size-7 pl-1"

  @spec new(HTTPRequestResult.t()) :: term
  def new(%HTTPRequestResult{updated_at: finished_at, inserted_at: started_at})
      when is_nil(finished_at) or is_nil(started_at) do
    content_tag(:span, "...", class: @default_class)
  end

  def new(%HTTPRequestResult{response: %HTTPResponse{} = response}) do
    duration =
      response.finished_at
      |> Timex.diff(response.started_at, :duration)
      |> Timex.format_duration(:humanized)

    content_tag(:span, duration, class: @default_class)
  end
end
