defmodule SmokexClientTest do
  use ExUnit.Case

  test "Given a smoke run plan file when the file exists then the yaml data is parsed" do
    {:ok, yaml_data} =
      YamlElixir.read_from_file("test/support/fixtures/execution_plan.yml", atoms: true)

    expected_get_step = %{
      "host" => "get_host_1",
      "query" => [
        %{"param_1" => "another_test"},
        %{"param_2" => "another_test"}
      ]
    }

    result_get_step = yaml_data |> Enum.at(0) |> Map.get("get")

    assert result_get_step === expected_get_step
  end

  test "Given a smoke run plan file when it has multiple steps then they are readed in order" do
    {:ok, yaml_data} =
      YamlElixir.read_from_file("test/support/fixtures/execution_plan.yml", atoms: true)

    yaml_data |> Enum.at(0) |> assert_step("get", "get_host_1")
    yaml_data |> Enum.at(1) |> assert_step("get", "get_host_2")
    yaml_data |> Enum.at(2) |> assert_step("post", "post_host_1")
    yaml_data |> Enum.at(3) |> assert_step("put", "put_host")
    yaml_data |> Enum.at(4) |> assert_step("post", "post_host_2")
  end

  defp assert_step(step, expected_step_type, expected_host_name) do
    assert Map.has_key?(step, expected_step_type)

    result_host_name = step |> Map.get(expected_step_type) |> Map.get("host")

    assert result_host_name === expected_host_name
  end
end
