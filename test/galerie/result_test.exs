defmodule ResultTest do
  use Galerie.BaseCase

  describe "from_nil/1" do
    test "returns ok tuple if non nil" do
      assert {:ok, :value} = Result.from_nil(:value, :not_found)
    end

    test "returns error tuple if nil" do
      assert :error = Result.from_nil(nil)
      assert {:error, :not_found} = Result.from_nil(nil, :not_found)
    end
  end

  describe "succeed/1" do
    test "returns an ok tuple" do
      assert {:ok, :value} = Result.succeed(:value)
    end
  end

  describe "fail/1" do
    test "returns an error tuple if value provided" do
      assert {:error, :not_found} = Result.fail(:not_found)
    end

    test "returns only :error if not value provided" do
      assert :error == Result.fail(nil)
    end
  end

  describe "succeeded?/1" do
    test "returns true if result is an ok tuple" do
      assert Result.succeeded?({:ok, :value})
    end

    test "returns fail if result is an error tuple" do
      refute Result.succeeded?({:error, :not_found})
    end
  end

  describe "unwrap!/1" do
    test "gets inner value if success" do
      assert :value == Result.unwrap!({:ok, :value})
    end

    test "raises if error" do
      assert_raise(FunctionClauseError, fn ->
        Result.unwrap!({:error, :not_found})
      end)
    end
  end

  describe "map/2" do
    test "maps inner value if success" do
      assert {:ok, "value"} == Result.map({:ok, :value}, &to_string/1)
    end

    test "returns the same value if error" do
      assert {:error, :not_found} == Result.map({:error, :not_found}, &to_string/1)
    end
  end
end
