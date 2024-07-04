defmodule Nectarine.TreeTest do
  use Nectarine.BaseCase
  alias Nectarine.Tree

  defmodule TreeImplementation do
    @behaviour Nectarine.Tree

    @impl Nectarine.Tree
    def identifier(%{type: type, kind: kind}), do: "#{type}/#{kind}"

    @impl Nectarine.Tree
    def load_children(%{type: :kid}) do
      # :call_cout gets incremented everytime this function is called
      # to keep track if the function is called
      call_count = Process.get(:call_count, 1)
      Process.put(:call_count, call_count + 1)

      [
        %{type: :parent, kind: :mother, call_count: call_count},
        %{type: :parent, kind: :father, call_count: call_count}
      ]
    end

    def load_children(%{type: :parent}) do
      [%{type: :grand_parent, kind: :mother}, %{type: :grand_parent, kind: :father}]
    end

    def load_children(_), do: []
  end

  setup [:initialize_tree]

  describe "new/2" do
    test "creates a tree", %{record: record} do
      identifier = TreeImplementation.identifier(record)

      assert %Tree{
               identifier: ^identifier,
               module: TreeImplementation,
               record: ^record,
               children: :not_loaded
             } = Tree.new(TreeImplementation, record)
    end
  end

  describe "load_children/2" do
    test "loads direct children", %{record: record, tree: tree} do
      assert %Tree{
               record: ^record,
               module: module,
               children: %{
                 "parent/mother" =>
                   %Tree{
                     identifier: "parent/mother",
                     record: %{kind: :mother, type: :parent, call_count: 1},
                     module: module,
                     children: :not_loaded
                   } = mother_tree,
                 "parent/father" => %Tree{
                   identifier: "parent/father",
                   record: %{kind: :father, type: :parent, call_count: 1},
                   children: :not_loaded,
                   module: module
                 }
               }
             } = loaded_tree = Tree.load_children(tree)

      assert %Tree{children: %{"parent/mother" => %Tree{record: %{call_count: 1}}}} =
               Tree.load_children(loaded_tree)

      assert %Tree{children: %{"parent/mother" => %Tree{record: %{call_count: 2}}}} =
               Tree.load_children(loaded_tree, force?: true)

      assert %Tree{
               identifier: "parent/mother",
               record: %{kind: :mother, type: :parent},
               module: module,
               children: %{
                 "grand_parent/mother" => %Tree{
                   identifier: "grand_parent/mother",
                   record: %{kind: :mother, type: :grand_parent},
                   module: module,
                   children: :not_loaded
                 },
                 "grand_parent/father" => %Tree{
                   identifier: "grand_parent/father",
                   record: %{kind: :father, type: :grand_parent},
                   children: :not_loaded,
                   module: module
                 }
               }
             } = Tree.load_children(mother_tree)
    end
  end

  describe "load_children_at/3" do
    test "loads children at a given path if not loaded", %{tree: tree} do
      assert %Tree{children: :not_loaded} = tree

      assert %Tree{
               children: %{
                 "parent/mother" => %Tree{children: :not_loaded}
               }
             } = Tree.load_children_at(tree, [])

      assert %Tree{
               children: %{
                 "parent/mother" => %Tree{
                   children: %{"grand_parent/mother" => %Tree{children: :not_loaded}}
                 }
               }
             } = Tree.load_children_at(tree, "parent/mother")

      assert %Tree{
               children: %{
                 "parent/mother" => %Tree{
                   children: %{"grand_parent/mother" => %Tree{children: :not_loaded}}
                 }
               }
             } = Tree.load_children_at(tree, ["parent/mother"])

      assert %Tree{
               children: %{
                 "parent/mother" => %Tree{
                   children: %{"grand_parent/mother" => %Tree{children: %{}}}
                 }
               }
             } = Tree.load_children_at(tree, ["parent/mother", "grand_parent/mother"])
    end

    test "doesn't reloads children at a given path loaded", %{tree: tree} do
      assert %Tree{children: :not_loaded} = tree

      assert %Tree{
               children: %{
                 "parent/mother" => %Tree{
                   record: %{call_count: 1},
                   children: %{"grand_parent/mother" => %Tree{}}
                 }
               }
             } = tree = Tree.load_children_at(tree, ["parent/mother"])

      assert %Tree{
               children: %{
                 "parent/mother" => %Tree{
                   record: %{call_count: 1},
                   children: %{"grand_parent/mother" => %Tree{}}
                 }
               }
             } = tree = Tree.load_children_at(tree, ["parent/mother"])

      assert %Tree{
               children: %{
                 "parent/mother" => %Tree{
                   record: %{call_count: 1},
                   children: %{"grand_parent/mother" => %Tree{}}
                 }
               }
             } = Tree.load_children_at(tree, ["parent/mother"], on_loaded: :nothing)
    end

    test "reloads children at a given path loaded", %{tree: tree} do
      assert %Tree{
               children: %{
                 "parent/mother" => %Tree{
                   record: %{call_count: 1},
                   children: :not_loaded
                 }
               }
             } = tree = Tree.load_children_at(tree, [])

      assert %Tree{
               children: %{
                 "parent/mother" => %Tree{
                   record: %{call_count: 2},
                   children: :not_loaded
                 }
               }
             } = Tree.load_children_at(tree, [], on_loaded: :reload)
    end

    test "unload children at a given path loaded", %{tree: tree} do
      assert %Tree{
               children: %{
                 "parent/mother" => %Tree{
                   record: %{call_count: 1},
                   children: %{"grand_parent/mother" => %Tree{}}
                 }
               }
             } = tree = Tree.load_children_at(tree, ["parent/mother"])

      assert %Tree{
               children: %{
                 "parent/mother" => %Tree{
                   record: %{call_count: 1},
                   children: :not_loaded
                 }
               }
             } = Tree.load_children_at(tree, ["parent/mother"], on_loaded: :unload)
    end
  end

  describe "loaded?/1" do
    test "is loaded if children is not :not_loaded", %{tree: tree} do
      refute Tree.loaded?(tree)

      assert tree
             |> Tree.load_children()
             |> Tree.loaded?()
    end
  end

  describe "get/2" do
    test "gets record at a given path even if not loaded", %{tree: tree} do
      assert %Tree{children: :not_loaded, identifier: "kid/teen"} = tree
      assert %{type: :kid, kind: :teen} = Tree.get(tree, [])

      assert %{type: :parent, kind: :mother} = Tree.get(tree, ["parent/mother"])

      assert %{type: :parent, kind: :mother} = Tree.get(tree, "parent/mother")

      assert %{type: :grand_parent, kind: :mother} =
               Tree.get(tree, ["parent/mother", "grand_parent/mother"])
    end

    test "gets nil if record doesn't match", %{tree: tree} do
      assert %Tree{children: :not_loaded, identifier: "kid/teen"} = tree

      assert nil ==
               Tree.get(tree, ["parent/uncle"])

      assert nil ==
               Tree.get(tree, ["parent/mother", "grand_parent/uncle"])
    end
  end

  describe "unload/1" do
    test "unloads a tree", %{tree: tree} do
      assert %Tree{children: :not_loaded} = tree
      assert %Tree{children: :not_loaded} = Tree.unload(tree)
      assert %Tree{children: %{}} = tree = Tree.load_children(tree)
      assert %Tree{children: :not_loaded} = Tree.unload(tree)
    end
  end

  describe "add_child/2" do
    test "adds a child to a tree", %{tree: tree} do
      assert %Tree{children: :not_loaded, module: tree_module} = tree

      record = %{type: :parent, kind: :father, call_count: 1}

      assert %Tree{
               children: %{
                 "parent/father" => %Tree{
                   children: :not_loaded,
                   identifier: "parent/father",
                   module: ^tree_module,
                   record: ^record
                 }
               }
             } = Tree.add_child(tree, record)
    end
  end

  describe "get_children/1" do
    test "gets empty map if not loaded", %{tree: tree} do
      assert %{} == Tree.get_children(tree)
    end

    test "gets children when loaded", %{tree: tree} do
      record = %{type: :parent, kind: :father, call_count: 1}

      assert %{"parent/father" => %Tree{}} =
               tree
               |> Tree.add_child(record)
               |> Tree.get_children()
    end
  end

  defp initialize_tree(context) do
    record = Map.get(context, :record, %{type: :kid, kind: :teen})
    tree = Tree.new(TreeImplementation, record)
    Process.put(:call_count, 1)

    [record: record, tree: tree]
  end
end
