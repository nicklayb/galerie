defmodule Fraction do
  defstruct [:numerator, :denominator]

  @type t :: %Fraction{numerator: integer(), denominator: integer()}

  @spec new({integer(), integer()} | float() | integer()) :: t()
  def new({numerator, denominator}) do
    new(numerator, denominator)
  end

  def new(numerator) when is_integer(numerator) do
    new(numerator, 1)
  end

  def new(float) when is_float(float) do
    float
    |> Float.to_string()
    |> String.split(".", parts: 2)
    |> then(fn [_, right] ->
      multiplier =
        10
        |> :math.pow(String.length(right))
        |> trunc()

      numerator = trunc(float * multiplier)
      new(numerator, multiplier)
    end)
  end

  def new(_, 0) do
    raise ArgumentError, message: "Attempted creating a fraction dividing by 0"
  end

  def new(numerator, denominator)
      when is_integer(numerator) and is_integer(denominator) do
    %Fraction{numerator: numerator, denominator: denominator}
  end

  def to_tuple(%Fraction{numerator: numerator, denominator: denominator}) do
    {numerator, denominator}
  end

  @fraction_regex ~r/(^[0-9]+)\/([0-9]+)$/
  def parse(string) do
    cond do
      Regex.match?(~r/^[0-9]+$/, string) ->
        String.to_integer(string)

      Regex.match?(@fraction_regex, string) ->
        parse_fraction(string)

      true ->
        raise ArgumentError, message: "Malformed fraction #{string}"
    end
  end

  defp parse_fraction(string) do
    case Regex.scan(@fraction_regex, string) do
      [[_, numerator, denominator]] ->
        numerator
        |> String.to_integer()
        |> new(String.to_integer(denominator))

      _ ->
        raise ArgumentError, message: "Malformed fraction #{string}"
    end
  end

  def to_string(%Fraction{denominator: same, numerator: same}), do: "1"

  def to_string(%Fraction{denominator: 1, numerator: numerator}), do: Integer.to_string(numerator)

  def to_string(%Fraction{} = fraction) do
    Enum.map_join([fraction.numerator, fraction.denominator], "/", &Integer.to_string/1)
  end
end
