defmodule SmokexWeb.PlansExecutionsLive.Components.Result.Row do
  use SmokexWeb, :live_component

  alias Smokex.Result

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, socket}
  end

  #
  # Private functions
  #

  # TODO this should always be a list
  def assertion_error_details(%Result{
        failed_assertions: failed_assertions
      })
      when is_list(failed_assertions) do
    Enum.map(failed_assertions, fn failed_assertion ->
      assertion_error_detail(failed_assertion)
    end)
  end

  def assertion_error_details(%Result{failed_assertions: failed_assertion})
      when is_map(failed_assertion) do
    assertion_error_detail(failed_assertion)
  end

  def assertion_error_details(_result), do: nil

  def assertion_error_detail(failed_assertion) when is_map(failed_assertion) do
    [{key, %{"expected" => expected, "received" => received}}] = Map.to_list(failed_assertion)

    content_tag(:tr, class: "is-not-hoverable details-row ml-6") do
      content_tag(:td, colspan: "6") do
        content_tag(:div, class: "columns ml-4") do
          content_tag(:div, class: "column content") do
            [
              content_tag(:p) do
                [
                  content_tag(:strong, "Field "),
                  content_tag(:span, key)
                ]
              end,
              content_tag(:p) do
                [
                  content_tag(:strong, "Expected "),
                  content_tag(:span, expected)
                ]
              end,
              content_tag(:p) do
                [
                  content_tag(:strong, "Received "),
                  content_tag(:span, received)
                ]
              end
            ]
          end
        end
      end
    end
  end
end
