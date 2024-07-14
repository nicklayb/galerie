defmodule Galerie.GeneratorTest do
  use Galerie.DataCase
  alias Galerie.Generator
  alias GalerieTest.Support.Mocks.MockGenerator

  describe "generate/2" do
    test "calls generator's function" do
      value = Ecto.UUID.generate()
      assert value == Generator.generate(MockGenerator, value: value)
    end
  end

  describe "generate/1" do
    test "calls generator's function" do
      value = Ecto.UUID.generate()
      assert value == Generator.generate({MockGenerator, value: value})
    end
  end

  describe "unique/2" do
    test "generate unique value without failing if value doesn't exist" do
      uuid = Ecto.UUID.generate()

      assert uuid ==
               Generator.unique({MockGenerator, value: uuid},
                 schema: {Galerie.Accounts.User, :email}
               )
    end

    test "tries multiple time if a value already exists" do
      [first, second, third] = sequence = Enum.map(1..3, fn _ -> Ecto.UUID.generate() end)
      insert!(:user, email: first)
      insert!(:user, email: second)

      assert third ==
               Generator.unique({MockGenerator, value: sequence},
                 schema: {Galerie.Accounts.User, :email}
               )
    end

    test "raises if max tries exceeds" do
      [first, second, third | _] = sequence = Enum.map(1..4, fn _ -> Ecto.UUID.generate() end)
      insert!(:user, email: first)
      insert!(:user, email: second)
      insert!(:user, email: third)

      assert_raise(RuntimeError, fn ->
        Generator.unique({MockGenerator, value: sequence},
          schema: {Galerie.Accounts.User, :email},
          max_tries: 3
        )
      end)
    end
  end
end
