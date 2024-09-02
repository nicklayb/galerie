defmodule Galerie.Ecto.Types.Permissions do
  @moduledoc """
  Permissions scheme for the non-admin users. It uses a binary format (similar to unix rwx).

  New permissions *must* but added to the bottom of the list and not in between.
  """
  use Ecto.ParameterizedType

  def type(_), do: :integer

  def init(options) do
    Keyword.get(options, :module)
  end

  def cast(integer, module) when is_integer(integer) do
    {:ok, module.to_permissions(integer)}
  end

  def cast(permissions, module) when is_list(permissions) do
    {:ok, module.to_permissions(permissions)}
  end

  def cast(_, _), do: :error

  def load(integer, _, module) when is_integer(integer) do
    {:ok, module.to_permissions(integer)}
  end

  def dump(permissions, _, module) when is_list(permissions) do
    {:ok, module.to_integer(permissions)}
  end

  def dump(_, _, _), do: :error
end
