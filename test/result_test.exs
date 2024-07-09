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

  describe "and_then/2" do
    test "maps succeded result to another result" do
      assert {:ok, :works} == Result.and_then({:ok, :value}, fn _ -> {:ok, :works} end)
      assert {:error, :failed} == Result.and_then({:ok, :value}, fn _ -> {:error, :failed} end)
    end

    test "returns the same value if error" do
      assert {:error, :not_found} == Result.map({:error, :not_found}, &to_string/1)
    end
  end

  describe "tap/3" do
    test "calls side effect success function if ok" do
      Process.delete(:ok)
      Process.delete(:error)
      refute Process.get(:ok)
      refute Process.get(:error)
      Result.tap({:ok, 1}, &Process.put(:ok, &1), &Process.put(:error, &1))
      assert 1 == Process.get(:ok)
      refute Process.get(:error)
    end

    test "calls side effect error function if error" do
      Process.delete(:ok)
      Process.delete(:error)
      refute Process.get(:ok)
      refute Process.get(:error)
      Result.tap({:error, :not_found}, &Process.put(:ok, &1), &Process.put(:error, &1))
      refute Process.get(:ok)
      assert :not_found == Process.get(:error)
    end

    test "errors fallbacks to identity" do
      Process.delete(:ok)
      Process.delete(:error)
      refute Process.get(:ok)
      refute Process.get(:error)
      Result.tap({:error, :not_found}, &Process.put(:ok, &1))
      refute Process.get(:ok)
      refute Process.get(:error)
    end
  end
end
