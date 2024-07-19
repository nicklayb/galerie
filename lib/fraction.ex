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
    |> to_string()
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
end
