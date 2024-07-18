defmodule Fraction do
  defstruct [:numerator, :denominator]

  def new({numerator, denominator}) do
    new(numerator, denominator)
  end

  def new(numerator, denominator \\ 1) when is_integer(numerator) and is_integer(denominator) do
    %Fraction{numerator: numerator, denominator: denominator}
  end

  def to_tuple(%Fraction{numerator: numerator, denominator: denominator}) do
    {numerator, denominator}
  end
end
