defmodule SmokexClient.Utils.StepVarsReplacer do
  alias Smokex.Step.Request

  @spec process_step_variables(list(Request.t())) :: list(Request.t())
  def process_step_variables(steps) when is_list(steps) do
    Enum.map(steps, &process_step_variables_/1)
  end

  @spec process_step_variables_(Request.t()) :: Request.t()
  def process_step_variables_(step) do
    step
    |> Map.from_struct()
    |> KitchenSink.Map.key_paths()
    |> replace_env_variables(step)
  end

  @spec replace_env_variables(list(String.t()), Request.t()) :: Request.t()
  defp replace_env_variables([], %Request{} = step), do: step

  defp replace_env_variables([key_path | rest], %Request{} = step) do
    {_changed_valued, updated_step} =
      step
      |> Map.from_struct()
      |> Kernel.get_and_update_in(key_path, &{&1, replace_env_variables_in_string(&1)})

    replace_env_variables(rest, struct(%Request{}, updated_step))
  end

  @spec replace_env_variables_in_string(String.t() | any) :: String.t()
  defp replace_env_variables_in_string(value) when is_binary(value) do
    Regex.replace(
      ~r/\${(\w+)}/,
      value,
      fn matched_key, var_key -> get_var_value(matched_key, var_key) end,
      capture: :all_but_first
    )
  end

  defp replace_env_variables_in_string(value), do: value

  @spec get_var_value(String.t(), String.t()) :: String.t()
  defp get_var_value(matched_key, key) do
    case System.get_env(key) do
      nil ->
        case Application.get_env(:smokex_client, key) do
          nil -> matched_key
          var -> var
        end

      value ->
        value
    end
  end
end
