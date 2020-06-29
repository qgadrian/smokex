defmodule SmokexClient.Printer do
  @moduledoc false

  alias SmokexClient.ExecutionState

  @spec print_result(any) :: no_return
  def print_result(result \\ :error) do
    case Application.get_env(:smokex_client, :output) do
      :console -> print_console_result(result)
      :json -> print_json_result()
    end
  end

  @spec print_console_result(any) :: no_return
  defp print_console_result(result) do
    IO.puts("")

    case result do
      :ok ->
        IO.puts([IO.ANSI.green(), 0x2714, " Sucess"])
        System.halt(0)

      {:error, message} when is_binary(message) ->
        IO.puts([IO.ANSI.red(), 0xD7, " Failed: ", message])
        System.halt(1)

      {:error, message} when is_atom(message) ->
        IO.puts([IO.ANSI.red(), 0xD7, " Failed: ", Atom.to_string(message)])
        System.halt(1)

      {:error, message} ->
        IO.puts([IO.ANSI.red(), 0xD7, " Failed: ", inspect(message)])
        System.halt(1)

      _error ->
        IO.puts([IO.ANSI.red(), 0xD7, " Failed"])
        System.halt(1)
    end
  end

  @spec print_json_result() :: no_return
  defp print_json_result() do
    results_to_print =
      ExecutionState.get_results()
      |> Enum.map(fn result ->
        case result.failed_assertions do
          nil ->
            Map.delete(result, :failed_assertions)

          _other ->
            result
        end
      end)

    IO.puts("#{Jason.encode!(results_to_print, pretty: true)}")
    System.halt(0)
  end

  @spec print_help() :: no_return
  def print_help() do
    IO.puts("""
      Usage:
        Smokex [execution_plan_file_path] [options]

        Example: Smokex ./my_smoke_test.yaml

      Options:
        -q --quiet             Excludes steps output information
        -o --output            Execution output format (default console): [console | json]
        -h --help              Print help (this message)
    """)

    System.halt(1)
  end
end
