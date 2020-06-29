defmodule SmokexClient do
  alias SmokexClient.Executor
  alias SmokexClient.Parsers.Yaml.Parser
  alias SmokexClient.Printer

  @default_quiet false
  @default_verbose false
  @default_output_type :console

  @type parsed_opts :: keyword
  @type non_parsed_opts :: list(String.t())

  @spec main(any) :: no_return
  def main(args) do
    args
    |> parse_args()
    |> process()
  end

  @spec parse_args(non_parsed_opts) :: {parsed_opts, non_parsed_opts}
  defp parse_args(args) do
    {options, remaining_opts, _invalid_args} =
      OptionParser.parse(
        args,
        switches: [quiet: :boolean, verbose: :boolean, output: :string, timeout: :integer],
        aliases: [q: :quiet, v: :verbose, o: :output, h: :help, t: :timeout]
      )

    {options, remaining_opts}
  end

  @spec process({parsed_opts, non_parsed_opts}) :: no_return
  defp process(args) do
    execution_plan_file_path = List.first(elem(args, 1)) || :error

    opts = elem(args, 0)

    if opts[:help] || execution_plan_file_path == :error do
      Printer.print_help()
    end

    opts
    |> set_execution_env()
    |> set_output_type()
    |> set_global_timeout()

    case Parser.parse(execution_plan_file_path) do
      {:ok, execution_plan} ->
        execution_plan
        |> Executor.execute()
        |> Printer.print_result()

      {:error, message} ->
        Printer.print_result({:error, message})
    end
  end

  @spec set_execution_env(parsed_opts) :: parsed_opts
  def set_execution_env(opts) do
    quiet? = opts[:quiet] || @default_quiet
    verbose? = opts[:verbose] || @default_verbose

    Application.put_env(:smokex_client, :quiet, quiet?)
    Application.put_env(:smokex_client, :verbose, verbose?)

    opts
  end

  @spec set_output_type(parsed_opts) :: parsed_opts
  defp set_output_type(opts) do
    case opts[:output] do
      "json" -> Application.put_env(:smokex_client, :output, :json)
      _other -> Application.put_env(:smokex_client, :output, @default_output_type)
    end

    opts
  end

  @spec set_global_timeout(parsed_opts) :: parsed_opts
  def set_global_timeout(opts) do
    Application.put_env(:smokex_client, :timeout, opts[:timeout])
    opts
  end
end
