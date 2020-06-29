defmodule SmokexClient.Printer.SmokeStep do
  alias Smokex.Step.Request

  def print_validation(result, message) do
    unless is_quiet?() do
      case result do
        :sucess ->
          IO.puts([IO.ANSI.green(), 0x2714, " ", message])

        :error ->
          IO.puts([IO.ANSI.red(), 0xD7, " ", message])

        :warn ->
          IO.puts([IO.ANSI.yellow(), 0x26A0, " ", message])

        _unrecognized_result ->
          IO.puts([IO.ANSI.red(), 0xD7, " ", "Unrecognized result type: #{inspect(result)}"])
      end

      IO.write(IO.ANSI.default_color())
    end
  end

  def print_step_info(%Request{} = step) do
    unless is_quiet?() do
      IO.puts([IO.ANSI.blue(), 0x2197, "\n", step.host, "\n"])

      if is_verbose?() do
        IO.puts([IO.ANSI.yellow(), 0x2197, " Body:"])
        IO.puts([IO.ANSI.white(), 0x2197, " ", inspect(step.body)])
        IO.puts([IO.ANSI.yellow(), 0x2197, " Headers:"])
        IO.puts([IO.ANSI.white(), 0x2197, " ", inspect(step.headers)])
        IO.puts([IO.ANSI.yellow(), 0x2197, " Query:"])
        IO.puts([IO.ANSI.white(), 0x2197, " ", inspect(step.query)])
        IO.puts("")
      end

      IO.write(IO.ANSI.default_color())
    end
  end

  defp is_quiet?() do
    Application.get_env(:smokex_client, :quiet) ||
      Application.get_env(:smokex_client, :env) == :test ||
      Application.get_env(:smokex_client, :output) != :console
  end

  defp is_verbose?() do
    Application.get_env(:smokex_client, :verbose) ||
      Application.get_env(:smokex_client, :env) == :test
  end
end
