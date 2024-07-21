defmodule SelectableLisTest do
  use Galerie.BaseCase

  @chars ~w(a b c d e f g)a
  @count length(@chars)

  setup [:create_selectable_list]

  describe "new/1" do
    test "creates a new indexed selectable list" do
      assert %SelectableList{
               items: %{},
               count: 0,
               selected_indexes: MapSet.new(),
               highlighted_index: nil,
               last_touched_index: nil
             } == SelectableList.new([])

      assert %SelectableList{
               items: %{
                 0 => :a,
                 1 => :b,
                 2 => :c,
                 3 => :d,
                 4 => :e,
                 5 => :f,
                 6 => :g
               },
               count: 7,
               selected_indexes: MapSet.new(),
               highlighted_index: nil,
               last_touched_index: nil
             } == SelectableList.new(@chars)
    end
  end

  describe "append/2" do
    test "appends new items with indexes and count increment", %{selectable_list: selectable_list} do
      assert %SelectableList{
               items: %{
                 0 => :a,
                 1 => :b,
                 2 => :c,
                 3 => :d,
                 4 => :e,
                 5 => :f,
                 6 => :g
               },
               count: 7,
               selected_indexes: MapSet.new(),
               highlighted_index: nil,
               last_touched_index: nil
             } == selectable_list

      assert %SelectableList{
               items: %{
                 0 => :a,
                 1 => :b,
                 2 => :c,
                 3 => :d,
                 4 => :e,
                 5 => :f,
                 6 => :g,
                 7 => :qwer,
                 8 => :asdf,
                 9 => :zxcv
               },
               count: 10,
               selected_indexes: MapSet.new(),
               highlighted_index: nil,
               last_touched_index: nil
             } == SelectableList.append(selectable_list, ~w(qwer asdf zxcv)a)
    end
  end

  describe "prepend/2" do
    test "prepends items and bumps indexes", %{selectable_list: selectable_list} do
      selectable_list =
        selectable_list
        |> SelectableList.highlight(3)
        |> SelectableList.select_by_index(4)
        |> SelectableList.select_by_index(5)

      assert %SelectableList{
               items: %{
                 0 => :a,
                 1 => :b,
                 2 => :c,
                 3 => :d,
                 4 => :e,
                 5 => :f,
                 6 => :g
               },
               count: 7,
               selected_indexes: MapSet.new([4, 5]),
               highlighted_index: 3,
               last_touched_index: 5
             } == selectable_list

      assert [{4, :e}, {5, :f}] = SelectableList.selected_items(selectable_list)

      prepended_selectable_list = SelectableList.prepend(selectable_list, ~w(qwer asdf zxcv)a)

      assert [{7, :e}, {8, :f}] = SelectableList.selected_items(prepended_selectable_list)

      assert %SelectableList{
               items: %{
                 0 => :qwer,
                 1 => :asdf,
                 2 => :zxcv,
                 3 => :a,
                 4 => :b,
                 5 => :c,
                 6 => :d,
                 7 => :e,
                 8 => :f,
                 9 => :g
               },
               count: 10,
               selected_indexes: MapSet.new([7, 8]),
               highlighted_index: 6,
               last_touched_index: 8
             } == prepended_selectable_list
    end
  end

  describe "select_by_index/2" do
    test "selects items if they are in the items", %{
      selectable_list: %{selected_indexes: selected_indexes} = selectable_list
    } do
      refute MapSet.member?(selected_indexes, 1)
      refute MapSet.member?(selected_indexes, 3)

      assert %SelectableList{selected_indexes: selected_indexes} =
               selectable_list = SelectableList.select_by_index(selectable_list, 1)

      assert MapSet.member?(selected_indexes, 1)
      refute MapSet.member?(selected_indexes, 3)

      assert %SelectableList{selected_indexes: selected_indexes} =
               SelectableList.select_by_index(selectable_list, 3)

      assert MapSet.member?(selected_indexes, 1)
      assert MapSet.member?(selected_indexes, 3)
    end
  end

  describe "highlight/2" do
    test "highlights item if possible", %{selectable_list: selectable_list} do
      assert %SelectableList{highlighted_index: nil} = selectable_list
      assert %SelectableList{highlighted_index: 3} = SelectableList.highlight(selectable_list, 3)

      assert %SelectableList{highlighted_index: nil} =
               SelectableList.highlight(selectable_list, @count)

      assert %SelectableList{highlighted_index: 6} =
               SelectableList.highlight(selectable_list, @count - 1)
    end
  end

  describe "highlight_next/2" do
    test "highlights next item if possible", %{selectable_list: selectable_list} do
      assert %SelectableList{highlighted_index: nil} =
               SelectableList.highlight_next(selectable_list)

      assert %SelectableList{highlighted_index: 3} =
               selectable_list = SelectableList.highlight(selectable_list, 3)

      assert %SelectableList{highlighted_index: 4} =
               selectable_list = SelectableList.highlight_next(selectable_list)

      assert %SelectableList{highlighted_index: 5} =
               selectable_list = SelectableList.highlight_next(selectable_list)

      assert %SelectableList{highlighted_index: 6} =
               selectable_list = SelectableList.highlight_next(selectable_list)

      assert %SelectableList{highlighted_index: 6} =
               SelectableList.highlight_next(selectable_list)
    end
  end

  describe "highlight_previous/2" do
    test "highlights previous item if possible", %{selectable_list: selectable_list} do
      assert %SelectableList{highlighted_index: nil} =
               SelectableList.highlight_previous(selectable_list)

      assert %SelectableList{highlighted_index: 3} =
               selectable_list = SelectableList.highlight(selectable_list, 3)

      assert %SelectableList{highlighted_index: 2} =
               selectable_list = SelectableList.highlight_previous(selectable_list)

      assert %SelectableList{highlighted_index: 1} =
               selectable_list = SelectableList.highlight_previous(selectable_list)

      assert %SelectableList{highlighted_index: 0} =
               selectable_list = SelectableList.highlight_previous(selectable_list)

      assert %SelectableList{highlighted_index: 0} =
               SelectableList.highlight_previous(selectable_list)
    end
  end

  describe "highlighted_item/1" do
    test "gets highlighted item if set", %{selectable_list: selectable_list} do
      refute SelectableList.highlighted_item(selectable_list)

      assert :c ==
               selectable_list
               |> SelectableList.highlight(2)
               |> SelectableList.highlighted_item()
    end
  end

  describe "first_highlighted?/1" do
    @tag items: ~w(a b c)a
    test "checks if last item is highlighted", %{selectable_list: selectable_list} do
      refute SelectableList.first_highlighted?(selectable_list)
      selectable_list = SelectableList.highlight(selectable_list, selectable_list.count - 1)
      refute SelectableList.first_highlighted?(selectable_list)
      selectable_list = SelectableList.highlight_previous(selectable_list)
      refute SelectableList.first_highlighted?(selectable_list)
      selectable_list = SelectableList.highlight_previous(selectable_list)
      assert SelectableList.first_highlighted?(selectable_list)
    end
  end

  describe "last_highlighted?/1" do
    @tag items: ~w(a b c)a
    test "checks if last item is highlighted", %{selectable_list: selectable_list} do
      refute SelectableList.last_highlighted?(selectable_list)
      selectable_list = SelectableList.highlight(selectable_list, 0)
      refute SelectableList.last_highlighted?(selectable_list)
      selectable_list = SelectableList.highlight_next(selectable_list)
      refute SelectableList.last_highlighted?(selectable_list)
      selectable_list = SelectableList.highlight_next(selectable_list)
      assert SelectableList.last_highlighted?(selectable_list)
    end
  end

  defp create_selectable_list(context) do
    items = Map.get(context, :items, @chars)

    [selectable_list: SelectableList.new(items)]
  end
end
