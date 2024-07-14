defmodule List.ExtraTest do
  use Galerie.BaseCase

  describe "at_least?/2" do
    test "true if list as at least x elements" do
      assert List.Extra.at_least?([], 0)
      refute List.Extra.at_least?([], 3)
      refute List.Extra.at_least?([1], 3)
      refute List.Extra.at_least?([1, 2], 3)
      assert List.Extra.at_least?([1, 2, 3], 3)
      assert List.Extra.at_least?([1, 2, 3, 4], 3)
      assert List.Extra.at_least?([1, 2, 3, 4, 5], 3)
    end
  end
end
