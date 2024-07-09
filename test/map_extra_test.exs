defmodule Map.ExtraTest do
  use Galerie.BaseCase

  describe "put/3" do
    test "puts value depending on key type" do
      assert %{key: :value} == Map.Extra.put(%{}, :key, :value)

      assert %{key: :value, other_key: :other_value} ==
               Map.Extra.put(%{key: :value}, :other_key, :other_value)

      assert %{"key" => :value, "other_key" => :other_value} ==
               Map.Extra.put(%{"key" => :value}, :other_key, :other_value)
    end
  end

  describe "get/2" do
    test "gets value depending on key type" do
      assert :value == Map.Extra.get(%{key: :value}, :key)
      assert :value == Map.Extra.get(%{"key" => :value}, :key)
      assert nil == Map.Extra.get(%{}, :key)
    end
  end

  describe "get_with_default/3" do
    test "get value from map defaulting even if value is present but nil" do
      assert :value = Map.Extra.get_with_default(%{key: :value}, :key, :fallback)
      assert :fallback = Map.Extra.get_with_default(%{key: nil}, :key, :fallback)
      assert :fallback = Map.Extra.get_with_default(%{}, :key, :fallback)
    end
  end

  describe "map_values/2" do
    test "maps only map value" do
      assert %{key: "value", other_key: "other_value"} =
               Map.Extra.map_values(%{key: :value, other_key: :other_value}, fn {_, value} ->
                 to_string(value)
               end)
    end
  end

  describe "update_if_exists/3" do
    test "update map entry if present, noop otherwise" do
      assert %{key: "value", other_key: :other_value} =
               Map.Extra.update_if_exists(
                 %{key: :value, other_key: :other_value},
                 :key,
                 &to_string/1
               )

      assert %{key: :value} ==
               Map.Extra.update_if_exists(%{key: :value}, :other_key, &to_string/1)
    end
  end

  describe "take/2" do
    test "takes only certain value no matter the key type" do
      assert %{key: :value} =
               Map.Extra.take(%{"key" => :value, "other_key" => :other_value}, [:key])

      assert %{key: :value} = Map.Extra.take(%{key: :value, other_key: :other_value}, [:key])
    end
  end

  describe "rename/4" do
    test "renames a key deleting the old one" do
      assert %{key_updated: :value, other_key: :other_value} =
               Map.Extra.rename(%{key: :value, other_key: :other_value}, :key, :key_updated)

      assert %{key_updated: :value, other_key: :other_value} =
               Map.Extra.rename(
                 %{key: :value, other_key: :other_value},
                 :key,
                 :key_updated,
                 :fallback
               )

      assert %{key_updated: :fallback, other_key: :other_value} =
               Map.Extra.rename(%{other_key: :other_value}, :key, :key_updated, :fallback)
    end
  end
end
