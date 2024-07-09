defmodule MapSet.ExtraTest do
  use Galerie.BaseCase

  describe "toggle/2" do
    test "add a value if missing, removes otherwise" do
      map_set = MapSet.new([1, 2])
      assert MapSet.new([1, 2, 3]) == MapSet.Extra.toggle(map_set, 3)
      assert MapSet.new([1]) == MapSet.Extra.toggle(map_set, 2)
    end
  end
end
