defmodule Galerie.Env do
  def test?, do: env() == :test

  defp env, do: Application.get_env(:galerie, :environment)

  def config(module, key, default \\ nil) do
    :galerie
    |> Application.get_env(module)
    |> Keyword.get(key, default)
  end
end
