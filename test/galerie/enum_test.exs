defmodule Enum.ExtraTest do
  use Galerie.BaseCase

  describe "replace/3" do
    test "replace value in enumerable" do
      assert [1, :two, 3, 4] = Enum.Extra.replace([1, 2, 3, 4], &(&1 == 2), :two)
    end
  end

  describe "key_by/2" do
    test "keys an enumerable by a given function" do
      assert %{one: 1, two: 2, three: 3} =
               Enum.Extra.key_by([1, 2, 3], fn
                 1 -> :one
                 2 -> :two
                 3 -> :three
               end)
    end
  end
end
