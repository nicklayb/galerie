defmodule FractionTest do
  use Galerie.BaseCase

  describe("new/1") do
    test "creates fraction from integer" do
      assert %Fraction{numerator: 10, denominator: 1} == Fraction.new(10)
      assert %Fraction{numerator: 1, denominator: 1} == Fraction.new(1)
      assert %Fraction{numerator: numerator, denominator: denominator} = Fraction.new(45)
      assert trunc(numerator / denominator) == 45
    end

    test "creates fraction from float" do
      assert %Fraction{numerator: 45, denominator: 10} == Fraction.new(4.5)
      assert %Fraction{numerator: 145, denominator: 100} == Fraction.new(1.45)
      assert %Fraction{numerator: 145_678, denominator: 100_000} == Fraction.new(1.45678)
      assert %Fraction{numerator: 145_678, denominator: 100} == Fraction.new(1456.78)
      assert %Fraction{numerator: numerator, denominator: denominator} = Fraction.new(45.12)
      assert numerator / denominator == 45.12
    end

    test "creates fraction from tuple" do
      assert %Fraction{numerator: 45, denominator: 10} == Fraction.new({45, 10})
      assert %Fraction{numerator: 145, denominator: 100} == Fraction.new({145, 100})
    end
  end

  describe "new/2" do
    test "creates fraction from numerator and denominator" do
      assert %Fraction{numerator: 12, denominator: 43} = Fraction.new(12, 43)
      assert %Fraction{numerator: 12, denominator: 1} = Fraction.new(12, 1)

      assert_raise(ArgumentError, fn ->
        Fraction.new(12, 0)
      end)
    end
  end

  describe "parse/1" do
    test "parses integer to fraction" do
      assert %Fraction{denominator: 1, numerator: 15} = Fraction.parse("15")
      assert %Fraction{denominator: 10, numerator: 155} = Fraction.parse("15.5")
      assert %Fraction{denominator: 120, numerator: 1} = Fraction.parse("1/120")
      assert %Fraction{denominator: 1, numerator: 1} = Fraction.parse("1")
    end
  end
end
