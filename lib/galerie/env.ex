defmodule Galerie.Env do
  @app_name :galerie

  @doc "True if app environment is test"
  @spec test?() :: boolean()
  def test?, do: env() == :test

  defp env, do: Application.get_env(@app_name, :environment)

  def config(module, key, default \\ nil) do
    module
    |> get_env()
    |> Keyword.get(key, default)
  end

  def config!(module, key) do
    module
    |> get_env()
    |> Keyword.fetch!(key)
  end

  defp get_env(key) do
    Application.get_env(@app_name, key)
  end
end
