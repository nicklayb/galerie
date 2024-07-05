defmodule GalerieTest.Support.MockConfig do
  def mock_config(root_key, opts) do
    root_key
    |> get_current_config()
    |> reset_on_test_exit()
    |> Config.__merge__([{root_key, opts}])
    |> put_config()
  end

  def mock_config(root_key, key, opts) do
    root_key
    |> get_current_config()
    |> reset_on_test_exit()
    |> Config.__merge__([{root_key, [{key, opts}]}])
    |> put_config()
  end

  defp get_current_config(root_key) do
    [{root_key, Application.get_all_env(root_key)}]
  end

  defp reset_on_test_exit([{root_key, _}] = config) do
    ExUnit.Callbacks.on_exit({Vegas.MockAppEnv, root_key}, fn ->
      Application.put_all_env(config)
    end)

    config
  end

  defp put_config(config) do
    Application.put_all_env(config)
  end
end
