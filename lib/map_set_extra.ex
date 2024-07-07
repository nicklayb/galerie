defmodule MapSet.Extra do
  @spec toggle(MapSet.t(), any()) :: MapSet.t()
  def toggle(%MapSet{} = map_set, item) do
    if MapSet.member?(map_set, item) do
      MapSet.delete(map_set, item)
    else
      MapSet.put(map_set, item)
    end
  end
end
