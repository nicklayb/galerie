defmodule Galerie.Ecto.Types.BinaryFlags do
  @moduledoc """
  Binary flags type for integer (binary based) flag list.

  New flags *must* but added to the bottom of the list and not in between.
  """
  use Ecto.ParameterizedType

  def type(_), do: :integer

  def init(options) do
    %{flags: Keyword.fetch!(options, :flags)}
  end

  def cast(integer, %{flags: available_flags}) when is_integer(integer) do
    {:ok, BinaryFlags.to_flags(available_flags, integer)}
  end

  def cast(flags, %{flags: available_flags}) when is_list(flags) do
    {:ok, BinaryFlags.to_flags(available_flags, flags)}
  end

  def cast(_, _), do: :error

  def load(integer, _, %{flags: available_flags}) when is_integer(integer) do
    {:ok, BinaryFlags.to_flags(available_flags, integer)}
  end

  def dump(flags, _, %{flags: available_flags}) when is_list(flags) do
    {:ok, BinaryFlags.to_integer(available_flags, flags)}
  end

  def dump(_, _, _), do: :error
end
