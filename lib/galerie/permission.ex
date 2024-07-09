defmodule Galerie.Permission do
  @moduledoc """
  Permissions scheme for the non-admin users. It uses a binary format (similar to unix rwx).

  New permissions *must* but added to the bottom of the list and not in between.
  """
  import Bitwise, only: [{:<<<, 2}]

  @permissions [
    :upload_pictures
  ]

  @type permission :: :upload_pictures | :do_stuff
  @type t :: [permission()]
  @type raw :: non_neg_integer()

  @permissions_binaries Enum.with_index(@permissions, &{&1, 0b1 <<< &2})

  @permissions_maximum Enum.reduce(@permissions_binaries, 0, fn {_, binary}, acc ->
                         acc + binary
                       end)

  @spec to_integer(t()) :: raw()
  def to_integer(permissions) when is_list(permissions) do
    Enum.reduce(@permissions_binaries, 0, fn {permission, binary}, acc ->
      if permission in permissions do
        acc + binary
      else
        acc
      end
    end)
  end

  @spec to_permissions(t() | raw()) :: t()
  def to_permissions(list) when is_list(list) do
    Enum.reject(list, &(&1 not in @permissions))
  end

  def to_permissions(integer)
      when is_integer(integer) and integer >= 0 and integer <= @permissions_maximum do
    Enum.reduce(@permissions_binaries, [], fn {permission, binary}, acc ->
      if Bitwise.band(integer, binary) > 0 do
        [permission | acc]
      else
        acc
      end
    end)
  end

  def to_permissions(integer) when is_integer(integer), do: []

  @spec permissions() :: t()
  def permissions, do: @permissions
end
