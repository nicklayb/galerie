defmodule Galerie.Ecto.Types.Permissions do
  @moduledoc """
  Permissions scheme for the non-admin users. It uses a binary format (similar to unix rwx).

  New permissions *must* but added to the bottom of the list and not in between.
  """
  use Ecto.Type

  alias Galerie.Accounts.Permission

  def type, do: :integer

  def cast(integer) when is_integer(integer) do
    {:ok, Permission.to_permissions(integer)}
  end

  def cast(permissions) when is_list(permissions) do
    {:ok, Permission.to_permissions(permissions)}
  end

  def cast(_), do: :error

  def load(integer) when is_integer(integer) do
    {:ok, Permission.to_permissions(integer)}
  end

  def dump(permissions) when is_list(permissions) do
    {:ok, Permission.to_integer(permissions)}
  end

  def dump(_), do: :error
end
