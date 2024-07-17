defmodule SelectableList do
  defstruct items: %{},
            selected_indexes: MapSet.new(),
            count: 0,
            last_touched_index: nil,
            highlighted_index: nil

  alias SelectableList

  @type index :: non_neg_integer()

  @type t(item_type) :: %SelectableList{
          items: %{index() => item_type},
          selected_indexes: MapSet.t(index()),
          count: non_neg_integer(),
          last_touched_index: index() | nil
        }

  @type t :: t(any())

  defguardp is_index_valid(selectable_list, index) when is_map_key(selectable_list.items, index)

  @spec highlight(t(), index()) :: t()
  def highlight(%SelectableList{} = selectable_list, index)
      when is_index_valid(selectable_list, index) do
    %SelectableList{selectable_list | highlighted_index: index}
  end

  def highlight(%SelectableList{} = selectable_list, _), do: selectable_list

  def last_highlighted?(%SelectableList{highlighted_index: hightlighted_index, count: count}),
    do: hightlighted_index == count - 1

  def first_highlighted?(%SelectableList{highlighted_index: highlighted_index}),
    do: highlighted_index == 0

  def highlight_previous(%SelectableList{highlighted_index: nil} = selectable_list),
    do: selectable_list

  def highlight_previous(%SelectableList{highlighted_index: highlighted_index} = selectable_list) do
    if not first_highlighted?(selectable_list) do
      highlight(selectable_list, highlighted_index - 1)
    else
      selectable_list
    end
  end

  def highlight_next(%SelectableList{highlighted_index: nil} = selectable_list),
    do: selectable_list

  def highlight_next(%SelectableList{highlighted_index: highlighted_index} = selectable_list) do
    if not last_highlighted?(selectable_list) do
      highlight(selectable_list, highlighted_index + 1)
    else
      selectable_list
    end
  end

  @spec highlighted_item(t()) :: any() | nil
  def highlighted_item(%SelectableList{highlighted_index: nil}), do: nil

  def highlighted_item(%SelectableList{items: items, highlighted_index: highlighted_index}) do
    Map.get(items, highlighted_index)
  end

  @spec new([any()]) :: t()
  def new(items) do
    {count, items_with_index} = with_index(items)
    %SelectableList{items: items_with_index, count: count}
  end

  @spec toggle_until(t(), index()) :: t()
  def toggle_until(
        %SelectableList{last_touched_index: last_touched_index} = selectable_list,
        new_index
      )
      when is_integer(last_touched_index) and new_index > last_touched_index do
    Enum.reduce((last_touched_index + 1)..new_index, selectable_list, &toggle_by_index(&2, &1))
  end

  def toggle_until(
        %SelectableList{last_touched_index: last_touched_index} = selectable_list,
        new_index
      )
      when is_integer(last_touched_index) and new_index < last_touched_index do
    Enum.reduce(new_index..(last_touched_index - 1), selectable_list, &toggle_by_index(&2, &1))
  end

  def toggle_until(%SelectableList{} = selectable_list, new_index) do
    select_by_index(selectable_list, new_index)
  end

  def selected?(%SelectableList{} = selectable_list, function_or_item) do
    case find_index(selectable_list, function_or_item) do
      {index, _} ->
        index_selected?(selectable_list, index)

      _ ->
        false
    end
  end

  def index_selected?(%SelectableList{selected_indexes: selected_indexes}, index) do
    MapSet.member?(selected_indexes, index)
  end

  @spec select_by_index(t(), index()) :: t()
  def select_by_index(
        %SelectableList{items: items, selected_indexes: selected_indexes} = selectable_list,
        index
      )
      when is_map_key(items, index) do
    %SelectableList{
      selectable_list
      | selected_indexes: MapSet.put(selected_indexes, index),
        last_touched_index: index
    }
  end

  @spec deselect_by_index(t(), index()) :: t()
  def deselect_by_index(
        %SelectableList{selected_indexes: selected_indexes} = selectable_list,
        index
      ) do
    %SelectableList{
      selectable_list
      | selected_indexes: MapSet.delete(selected_indexes, index),
        last_touched_index: index
    }
  end

  @spec toggle_by_index(t(), index()) :: t()
  def toggle_by_index(
        %SelectableList{items: items, selected_indexes: selected_indexes} = selectable_list,
        index
      )
      when is_map_key(items, index) do
    %SelectableList{
      selectable_list
      | selected_indexes: MapSet.Extra.toggle(selected_indexes, index),
        last_touched_index: index
    }
  end

  @type function_or_item :: (any() -> boolean()) | (any(), index() -> boolean()) | any()

  @spec select(t(), function_or_item()) :: t()
  def select(%SelectableList{} = selectable_list, function_or_item) do
    case find_index(selectable_list, function_or_item) do
      {index, _} ->
        select_by_index(selectable_list, index)

      _ ->
        selectable_list
    end
  end

  @spec deselect(t(), function_or_item()) :: t()
  def deselect(%SelectableList{} = selectable_list, function_or_item) do
    case find_index(selectable_list, function_or_item) do
      {index, _} ->
        deselect_by_index(selectable_list, index)

      _ ->
        selectable_list
    end
  end

  @spec toggle(t(), function_or_item()) :: t()
  def toggle(%SelectableList{} = selectable_list, function_or_item) do
    case find_index(selectable_list, function_or_item) do
      {index, _} ->
        toggle_by_index(selectable_list, index)

      _ ->
        selectable_list
    end
  end

  @spec selected_items(t()) :: [t()]
  def selected_items(%SelectableList{items: items, selected_indexes: selected_indexes}) do
    selected_indexes
    |> Enum.sort()
    |> Enum.map(&Map.fetch!(items, &1))
  end

  @spec prepend(t(), [any()]) :: t()
  def prepend(
        %SelectableList{
          items: items,
          last_touched_index: last_touched_index,
          highlighted_index: highlighted_index,
          selected_indexes: selected_indexes,
          count: count
        } = selectable_list,
        new_items
      ) do
    {new_items_count, new_items_with_index} = with_index(new_items)

    bumped_items =
      Enum.reduce(items, %{}, fn {index, item}, acc ->
        Map.put(acc, index + new_items_count, item)
      end)

    bumped_selected_indexes =
      Enum.reduce(selected_indexes, MapSet.new(), fn index, acc ->
        MapSet.put(acc, index + new_items_count)
      end)

    %SelectableList{
      selectable_list
      | count: count + new_items_count,
        items: Map.merge(new_items_with_index, bumped_items),
        selected_indexes: bumped_selected_indexes,
        highlighted_index: highlighted_index + new_items_count,
        last_touched_index: last_touched_index + new_items_count
    }
  end

  @spec append(t(), [any()]) :: t()
  def append(%SelectableList{items: items, count: count} = selectable_list, new_items) do
    {new_count, new_item_with_index} = with_index(new_items, count)

    %SelectableList{
      selectable_list
      | items: Map.merge(items, new_item_with_index),
        count: new_count
    }
  end

  def slice(%SelectableList{items: items}, start_index, count) do
    range = start_index..(start_index + (count - 1))

    Enum.map(range, fn index ->
      Map.fetch!(items, index)
    end)
  end

  defp with_index(items, start_index \\ 0) do
    Enum.reduce(items, {start_index, %{}}, fn item, {current_index, acc} ->
      {current_index + 1, Map.put(acc, current_index, item)}
    end)
  end

  defp find_index(%SelectableList{items: items}, function_or_item) do
    Enum.find(items, &item_matches?(&1, function_or_item))
  end

  defp item_matches?({_, item}, function) when is_function(function, 1), do: function.(item)

  defp item_matches?({index, item}, function) when is_function(function, 2),
    do: function.(item, index)

  defp item_matches?({_, item}, check_item), do: item == check_item
end

defimpl Enumerable, for: SelectableList do
  def count(%SelectableList{count: count}) do
    {:ok, count}
  end

  def member?(%SelectableList{items: items}, value) do
    {:ok, Enum.any?(items, fn {_, current_value} -> current_value == value end)}
  end

  def member?(_map, _other) do
    {:ok, false}
  end

  def slice(%SelectableList{count: count} = selectable_list) do
    {:ok, count, &SelectableList.slice(selectable_list, &1, &2)}
  end

  def reduce(%SelectableList{items: items}, acc, fun) do
    items
    |> :maps.to_list()
    |> Enumerable.List.reduce(acc, fun)
  end
end
