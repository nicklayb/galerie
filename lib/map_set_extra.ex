defmodule MapSet.Extra do
  @moduledoc """
  Extra functions to work with MapSets.
  """

  @doc """
  Removes the item if present, adds if missing
  """
  @spec toggle(MapSet.t(), any()) :: MapSet.t()
  def toggle(%MapSet{} = map_set, item) do
    if MapSet.member?(map_set, item) do
      MapSet.delete(map_set, item)
    else
      MapSet.put(map_set, item)
    end
  end
end
