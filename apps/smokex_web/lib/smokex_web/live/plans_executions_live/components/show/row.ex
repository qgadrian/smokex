#
# TODO this module requires a HUGE refactor and sync with the `Smokex.Result` module to cleanup the pattern matching with String, atoms, keys format...
# It needs to be a fixed struct and stop playing around with maps a types!
#
defmodule SmokexWeb.PlansExecutionsLive.Components.Show.Row do
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
    failed_assertion
    |> Map.to_list()
    |> Enum.map(fn assertion ->
      create_tag(assertion)
    end)
  end

  defp create_tag({key, %{"expected" => expected, "received" => received}}) do
    build_tag(key, expected, received)
  end

  defp create_tag({key, %{expected: expected, received: received}}) do
    build_tag(key, expected, received)
  end

  defp create_tag({"headers", failed_headers}) do
    Enum.map(failed_headers, fn %{
                                  "expected" => expected,
                                  "received" => received,
                                  "header" => header_name
                                } ->
      expected = "#{header_name} to be #{expected}"
      build_tag("headers", expected, received)
    end)
  end

  defp create_tag({:headers, failed_headers}) do
    Enum.map(failed_headers, fn %{
                                  expected: expected,
                                  received: received,
                                  header: header_name
                                } ->
      expected = "#{header_name} to be #{expected}"
      build_tag("headers", expected, received)
    end)
  end

  defp create_tag({"error", "Free limit reached"}) do
    content_tag(:tr, class: "is-not-hoverable details-row ml-6") do
      content_tag(:td, colspan: "6") do
        content_tag(:div, class: "columns ml-4") do
          content_tag(:div, class: "column content") do
            [
              content_tag(:p) do
                [
                  content_tag(:strong, "Free limit executions reached ")
                ]
              end
            ]
          end
        end
      end
    end
  end

  defp create_tag({"error", reason}) do
    build_tag("request", "to be successfully sent", reason)
  end

  defp create_tag(error: reason) do
    build_tag("request", "to be successfully sent", reason)
  end

  defp create_tag(status_code: %{expected: expected, received: received}) do
    build_tag("status_code", expected, received)
  end

  defp build_tag(key, expected, received) do
    content_tag(:tr, class: "is-not-hoverable details-row ml-6") do
      content_tag(:td, colspan: "6") do
        content_tag(:div, class: "columns ml-4") do
          content_tag(:div, class: "column content") do
            content_tags(key, expected, received)
          end
        end
      end
    end
  end

  defp content_tags(key, expected, received) do
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
          content_tag(:span, parse_expected(expected))
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

  defp parse_expected(expected) when is_map(expected) do
    Jason.encode!(expected)
  end

  defp parse_expected(expected), do: inspect(expected)
end