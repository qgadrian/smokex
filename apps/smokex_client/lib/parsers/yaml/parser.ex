defmodule SmokexClient.Parsers.Yaml.Parser do
  alias Smokex.Step.Request
  alias Smokex.Step.Request.Expect
  alias Smokex.Step.Request.SaveFromResponse

  @expect_params ["status_code", "headers", "body"]

  @step_opts ["timeout"]

  @type requests :: list(Request.t())

  @doc "Reads a yaml file and returns a list of [requests](`t:#{Request}`)"
  @spec parse_file!(String.t()) :: requests() | no_return
  def parse_file!(yaml_file_path) do
    yaml_file_path
    |> File.read!()
    |> parse!()
  end

  @doc "Reads a yaml file and returns a list of [requests](`t:#{Request}`)"
  @spec parse_file!(String.t()) :: {:ok, requests()} | {:error, term}
  def parse_file(yaml_file_path) do
    with {:ok, file_content} <- File.read(yaml_file_path) do
      parse(file_content)
    else
      _ ->
        {:error, "Error reading yaml file"}
    end
  end

  @doc "Parses a yaml string content and returns a list of [requests](`t:#{Request}`)"
  @spec parse!(String.t()) :: list(Request.t()) | no_return
  def parse!(yaml_as_string) do
    case parse(yaml_as_string) do
      {:ok, parse_result} -> parse_result
      error -> throw(error)
    end
  end

  @doc "Parses a yaml string content and returns a list of [requests](`t:#{Request}`)"
  @spec parse(String.t()) :: {:ok, list(Request.t())} | {:error, String.t()}
  def parse(yaml_as_string) do
    with {:ok, yaml_map} <- YamlElixir.read_from_string(yaml_as_string) do
      steps_maps = Enum.map(yaml_map, &parse_step(&1))
      {:ok, steps_maps}
    else
      {:error, _message} ->
        {:error, "Invalid yaml file"}
    end
  end

  @spec parse_step(map) :: struct
  defp parse_step(yaml_step) do
    with %{action: action, props: props} <- get_action(yaml_step),
         host <- get_host(props),
         query_params <- get_query_params(props),
         body <- get_body(props),
         headers <- get_headers(props),
         %Expect{} = expect <- get_expect(props),
         save_from_response <- get_save_from_response(props),
         opts <- get_opts(props) do
      %Request{
        action: action,
        host: host,
        query: query_params,
        body: body,
        expect: expect,
        headers: headers,
        save_from_response: save_from_response,
        opts: opts
      }
    else
      {:error, :invalid_action} ->
        {:error, "Invalid action"}

      {:error, :invalid_host} ->
        {:error, "Invalid host"}

      _ ->
        {:error, "Unknown error parsing yaml"}
    end
  end

  @spec get_action(map) :: map
  defp get_action(yaml_step) do
    yaml_step_action = yaml_step |> Map.to_list() |> Enum.at(0) |> elem(0)

    case yaml_step_action do
      nil -> {:error, :invalid_action}
      action -> %{action: action, props: Map.get(yaml_step, yaml_step_action)}
    end
  end

  @spec get_host(map) :: String.t()
  defp get_host(yaml_step_props) do
    case Map.get(yaml_step_props, "host") do
      nil -> {:error, :invalid_host}
      host -> host
    end
  end

  @spec get_query_params(map) :: map
  defp get_query_params(yaml_step_props) do
    Map.get(yaml_step_props, "query", %{})
  end

  @spec get_body(map) :: map
  defp get_body(yaml_step_props) do
    Map.get(yaml_step_props, "body", %{})
  end

  @spec get_headers(map) :: map
  defp get_headers(yaml_step_props) do
    Map.get(yaml_step_props, "headers", %{})
  end

  @spec get_expect(map) :: map
  defp get_expect(yaml_step_props) do
    yaml_step_props
    |> Map.get("expect", %{})
    |> Map.take(@expect_params)
    |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    |> Expect.new()
  end

  @spec get_opts(map) :: keyword
  defp get_opts(yaml_step_props) do
    yaml_step_props
    |> Map.get("options", %{})
    |> Map.take(@step_opts)
    |> Map.to_list()
    |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    |> Keyword.new()
  end

  @spec get_save_from_response(map) :: list(SaveFromResponse.t())
  def get_save_from_response(map) do
    save_from_respose_maps =
      map
      |> Map.get("save_from_response", %{})
      |> Enum.map(&Enum.map(&1, fn {key, value} -> {String.to_atom(key), value} end))
      |> Enum.map(&Enum.into(&1, %{}))

    Enum.map(save_from_respose_maps, &struct(SaveFromResponse, &1))
  end
end
