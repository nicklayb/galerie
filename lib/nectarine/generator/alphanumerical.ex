defmodule Nectarine.Generator.Alphanumerical do
  @moduledoc """
  Generates an alphanumerical string. Parts can be given
  as argument to filter lowercase, uppercase or numbers
  out of the range possibility.

  ## Options

  - `parts`: `:all` or a list of `:uppercase`, `:lowercase` or `:numbers`
  - `length`
  """
  @behaviour Nectarine.Generator

  @lowercase "abcdefghijklmnopqrstuvwxyx"
  @uppercase String.upcase(@lowercase)
  @numbers Enum.join(0..9, "")
  @parts %{lowercase: @lowercase, uppercase: @uppercase, numbers: @numbers}

  @impl Nectarine.Generator
  def generate(options) do
    available_characters =
      options
      |> Keyword.get(:parts, :all)
      |> characters_parts()

    options
    |> Keyword.put(:characters, available_characters)
    |> Nectarine.Generator.Characters.generate()
  end

  defp characters_parts(:all) do
    @parts
    |> Map.values()
    |> Enum.join("")
  end

  defp characters_parts(parts) do
    Enum.reduce(parts, "", fn part, acc ->
      part = Map.fetch!(@parts, part)
      acc <> part
    end)
  end
end
