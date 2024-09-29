defmodule Galerie.Explorer do
  defstruct [:implementation, :parent, :items]

  alias Galerie.Explorer

  @type item :: any()
  @type identity :: any()
  @type element :: {:branch, item()} | {:leaf, item()}
  @callback identity(item()) :: identity()
  @callback children(item()) :: [element()] | {item(), [element()]}

  def new(%Explorer{} = parent, items) do
    explorer = new(parent.implementation, items)
    %Explorer{explorer | parent: parent}
  end

  def new(implementation, items) when is_atom(implementation) do
    %Explorer{implementation: implementation, items: items}
  end

  def enter(%Explorer{} = explorer, identity) do
    {children, updated_items} = update_child_by_identity(explorer, identity)

    explorer
    |> put_items(updated_items)
    |> new(children)
  end

  def back(%Explorer{parent: parent}) do
    parent
  end

  defp put_items(%Explorer{} = explorer, items) do
    %Explorer{explorer | items: items}
  end

  defp update_child_by_identity(%Explorer{items: items} = explorer, identity) do
    {children, updated_items} =
      Enum.reduce(items, {[], []}, fn {type, item}, {current_children, updated_items} ->
        if identity(explorer, item) == identity do
          {new_item, children} = children(explorer, item)
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

  defp children(%Explorer{implementation: implementation}, item) do
    case implementation.children(item) do
      {new_item, children} -> {new_item, children}
      children -> {item, children}
    end
  end
end
