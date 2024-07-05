defmodule Galerie.Generator.Characters do
  @moduledoc """
  Random string generator from a character string

  ## Options

  - `characters`: Any string of allowed characters
  - `length`
  """
  @behaviour Galerie.Generator

  @impl Galerie.Generator
  def generate(options) do
    available_characters =
      options
      |> Keyword.fetch!(:characters)
      |> String.codepoints()

    length = Keyword.fetch!(options, :length)

    Enum.reduce(1..length, "", fn _, acc ->
      acc <> Enum.random(available_characters)
    end)
  end
end
