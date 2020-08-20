defmodule SmokexClient.Utils.StepVarsReplacer do
  @moduledoc """
  Module that replaces any value in a #{Request} structure with a variable
  reference.
  """
  require Logger

  alias Smokex.Step.Request
  alias SmokexClient.ExecutionContext

  @spec process_step_variables(list(Request.t()), map) :: list(Request.t())
  def process_step_variables(steps, available_variables \\ %{}) when is_list(steps) do
    Enum.map(steps, fn
      step -> process_step_variables_(step, available_variables)
    end)
  end

  # TODO this can be handled by pattern matching
  @spec process_step_variables_(Request.t(), ExecutionContext.t() | map) :: Request.t()
  def process_step_variables_(step, state_or_available_variables \\ %{})

  def process_step_variables_(step, %ExecutionContext{save_from_responses: save_from_responses}) do
    step
    |> SmokexClient.Utils.Map.key_paths()
    |> replace_env_variables(step, save_from_responses)
  end

  def process_step_variables_(step, available_variables)
      when is_map(available_variables) do
    step
    |> SmokexClient.Utils.Map.key_paths()
    |> replace_env_variables(step, available_variables)
  end

  @spec replace_env_variables(list(String.t()), Request.t(), map) :: Request.t()
  defp replace_env_variables([], %Request{} = step, _available_variables), do: step

  defp replace_env_variables(
         [key_path | rest],
         %Request{} = step,
         available_variables
       ) do
    {_changed_valued, updated_step} =
      step
      |> SmokexClient.Utils.Map.from_struct()
      |> Kernel.get_and_update_in(key_path, fn value ->
        {value, replace_env_variables_in_string(value, available_variables)}
      end)

    expect_map = Map.get(updated_step, :expect)

    reconstructed_expect =
      case expect_map do
        nil -> nil
        expect_map -> struct(%Smokex.Step.Request.Expect{}, expect_map)
      end

    save_from_response = Map.get(updated_step, :save_from_response)

    reconstructed_save_from_response =
      Enum.map(save_from_response, fn save_from_response ->
        struct(%Smokex.Step.Request.SaveFromResponse{}, save_from_response)
      end)

    reconstructed_step =
      %Request{}
      |> struct(updated_step)
      |> Map.put(:expect, reconstructed_expect)
      |> Map.put(:save_from_response, reconstructed_save_from_response)

    replace_env_variables(rest, reconstructed_step, available_variables)
  end

  @spec replace_env_variables_in_string(String.t() | term, map) :: String.t()
  defp replace_env_variables_in_string(value, available_variables)
       when is_binary(value) do
    case Regex.run(~r/^\${(\w+)}$/, value) do
      nil ->
        Regex.replace(
          ~r/.*(\${\w+}).*/,
          value,
          fn original_string, var_key ->
            [_, replacement_key] = Regex.run(~r/^\${(\w+)}$/, var_key)

            replacement_value =
              get_var_value(replacement_key, available_variables, original_string)

            case replacement_value do
              ^original_string ->
                original_string

              replacement_value ->
                String.replace(original_string, var_key, replacement_value)
            end
          end
        )

      [original_string, replacement_key] ->
        get_var_value(replacement_key, available_variables, original_string)
    end
  end

  defp replace_env_variables_in_string(value, _executor_state), do: value

  @spec get_var_value(String.t(), map, String.t()) :: String.t()
  defp get_var_value(key, available_variables, default_value) do
    if is_atom(key) do
      Logger.warn("Variables key should not be atoms, found: #{key}")
    end

    case System.get_env(key) do
      nil ->
        case Map.get(available_variables, key) do
          nil -> default_value
          var when is_binary(var) -> var
          var when is_number(var) -> var
          var when is_boolean(var) -> var
          var -> "#{var}"
        end

      value ->
        value
    end
  end
end
