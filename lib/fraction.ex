defmodule Fraction do
  @moduledoc """
  Fraction type to work with irrational numbers. The fractions
  are *not* simplified. At the moment, it also doesn't support 
  negative fractions.
  """
  defstruct [:numerator, :denominator]

  @type t :: %Fraction{numerator: integer(), denominator: integer()}

  @doc "Creates a fraction from primitive types, for strings, see `parse/1`"
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

  @doc """
  Creates a fraction from numerator and denominator
  """
  @spec new(integer(), integer()) :: t()
  def new(_, 0) do
    raise ArgumentError, message: "Attempted creating a fraction dividing by 0"
  end

  def new(numerator, denominator)
      when is_integer(numerator) and is_integer(denominator) do
    %Fraction{numerator: numerator, denominator: denominator}
  end

  @doc "Converts to float"
  @spec to_tuple(t()) :: {integer(), integer()}
  def to_tuple(%Fraction{numerator: numerator, denominator: denominator}) do
    {numerator, denominator}
  end

  @doc "Converts to float"
  @spec to_float(t()) :: Float.t()
  def to_float(%Fraction{numerator: numerator, denominator: denominator}) do
    numerator / denominator
  end

  @integer_regex ~r/^[0-9]+$/
  @float_regex ~r/^[0-9]+\.[0-9]+$/
  @fraction_regex ~r/(^[0-9]+)\/([0-9]+)$/
  @doc """
  Parses a string to a fraction type. It supports parsing the
  following formats: 

  - Integer (`"43"`): rendered as `%Fraction{numerator: 43, denominator: 1}`
  - Float (`"12.1"`): rendered as `%Fraction{numerator: 121, denominator: 10}`
  - Fraction (`"12/14"`): rendered as `%Fraction{numerator: 12, denominator: 14}`
  """
  @spec parse(String.t()) :: Fraction.t()
  def parse(string) do
    cond do
      Regex.match?(@integer_regex, string) ->
        string
        |> String.to_integer()
        |> Fraction.new()

      Regex.match?(@float_regex, string) ->
        string
        |> String.to_float()
        |> Fraction.new()

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

  @doc """
  Converts a fraction to string.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%Fraction{denominator: same, numerator: same}), do: "1"

  def to_string(%Fraction{denominator: 1, numerator: numerator}), do: Integer.to_string(numerator)

  def to_string(%Fraction{denominator: denominator, numerator: numerator} = fraction)
      when numerator > denominator do
    fraction
    |> to_float()
    |> Float.to_string()
  end

  def to_string(%Fraction{} = fraction) do
    Enum.map_join([fraction.numerator, fraction.denominator], "/", &Integer.to_string/1)
  end

  @doc """
  Compares two fraction. The fractions are compared using
  their float conversion in order to make sure unsimplified
  expression gets invalid results.
  """
  @spec compare(t(), t()) :: :gt | :lt | :eq
  def compare(%Fraction{} = left, %Fraction{} = right) do
    left_float = to_float(left)
    right_float = to_float(right)

    cond do
      left_float > right_float -> :gt
      left_float < right_float -> :lt
      true -> :eq
    end
  end
end

defimpl Phoenix.HTML.Safe, for: Fraction do
  def to_iodata(%Fraction{} = fraction) do
    Fraction.to_string(fraction)
  end
end
