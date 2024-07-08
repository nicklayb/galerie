defmodule Galerie.FileSize do
  alias Galerie.FileSize

  @type unit :: :kilo | :mega | :giga | :tera | :peta
  @type t :: {non_neg_integer(), unit()}

  @units ~w(kilo mega giga tera peta)a
  @unit_map Enum.reduce(@units, %{}, fn unit, acc ->
              key =
                unit
                |> to_string()
                |> String.at(0)

              Map.put(acc, key, unit)
            end)

  @multiplier 1000

  @regex ~r/^([0-9]+)([kmgtp]?)b?$/

  @doc "Parses a string to bytes"
  @spec parse(String.t()) :: non_neg_integer()
  def parse(string) do
    case Regex.scan(@regex, string) do
      [[_, amount_string, unit]] ->
        amount = String.to_integer(amount_string)
        unit = Map.get(@unit_map, String.downcase(unit))

        to_minimum_unit(amount, unit)

      _ ->
        raise ArgumentError, message: "expected format like 1mb or 34Gb"
    end
  end

  defp to_minimum_unit(amount, nil) do
    amount
  end

  defp to_minimum_unit(amount, unit) do
    Enum.reduce_while(@units, amount * @multiplier, fn
      ^unit, acc ->
        {:halt, acc}

      _, acc ->
        {:cont, acc * @multiplier}
    end)
  end

  def to_integer({amount, nil}), do: amount

  def to_integer({amount, unit}) do
    Enum.reduce_while(@units, amount, fn
      ^unit, value ->
        {:halt, value * @multiplier}

      _, value ->
        {:cont, value * @multiplier}
    end)
  end

  @doc "Simplifies a number of bytes to the biggest unit"
  @spec simplify(non_neg_integer()) :: t()
  def simplify(integer) do
    Enum.reduce_while(@units, {integer, nil}, fn unit, {acc, current_unit} ->
      if div(acc, @multiplier) == 0 do
        {:halt, {acc, current_unit}}
      else
        {:cont, {div(acc, @multiplier), unit}}
      end
    end)
  end

  @doc "Converts a number of bytes to string"
  @spec to_string(non_neg_integer() | t()) :: String.t()
  def to_string(integer) when is_integer(integer) do
    integer
    |> simplify()
    |> FileSize.to_string()
  end

  def to_string({integer, nil}) do
    Integer.to_string(integer) <> "b"
  end

  def to_string({integer, unit}) do
    char =
      unit
      |> Atom.to_string()
      |> String.at(0)

    Integer.to_string(integer) <> char <> "b"
  end
end
