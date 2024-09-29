defmodule Galerie.Explorer do
  defstruct [:implementation, :parent, :items]

  alias Galerie.Explorer

  @type item :: any()
  @type identity :: any()
  @type element :: {:branch, item()} | {:leaf, item()}
  @type kind :: :branches | :leaves
  @callback identity(item()) :: identity()
  @callback children(item(), kind()) :: [element()] | {item(), [element()]}

  def new(%Explorer{} = parent, items) do
    explorer = new(parent.implementation, items)
    %Explorer{explorer | parent: parent}
  end

  def new(implementation, items) when is_atom(implementation) do
    %Explorer{implementation: implementation, items: items}
  end

  def enter(%Explorer{} = explorer, identity, options \\ []) do
    {children, updated_items} = update_child_by_identity(explorer, identity, options)

    explorer
    |> put_items(updated_items)
    |> new(children)
  end

  def back(%Explorer{parent: parent}) do
    parent
  end

  def find_by_identity(%Explorer{items: items} = explorer, identity) do
    Enum.find_value(items, fn {_, item} ->
      if identity(explorer, item) == identity do
        item
      end
    end)
  end

  defp put_items(%Explorer{} = explorer, items) do
    %Explorer{explorer | items: items}
  end

  defp update_child_by_identity(%Explorer{items: items} = explorer, identity, options) do
    kind = Keyword.get(options, :kind, :both)

    {children, updated_items} =
      Enum.reduce(items, {[], []}, fn {type, item}, {current_children, updated_items} ->
        if identity(explorer, item) == identity do
          {new_item, children} = children(explorer, item, kind)
          {children, [{type, new_item} | updated_items]}
        else
          {current_children, [{type, item} | updated_items]}
        end
      end)

    {children, Enum.reverse(updated_items)}
  end

  defp identity(%Explorer{implementation: implementation}, item) do
    implementation.identity(item)
  end

  defp children(%Explorer{} = explorer, item, kind) when is_atom(kind) do
    kinds =
      case kind do
        :both -> [:branches, :leaves]
        one -> [one]
      end

    children(explorer, item, kinds)
  end

  defp children(%Explorer{implementation: implementation}, item, kinds) do
    Enum.reduce(kinds, {item, []}, fn kind, {current_item, current_items} ->
      {updated_item, children} =
        case implementation.children(current_item, kind) do
          {new_item, children} -> {new_item, children}
          children -> {current_item, children}
        end

      {updated_item, current_items ++ Enum.reverse(children)}
    end)
  end
end
