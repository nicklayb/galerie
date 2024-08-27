defmodule Galerie.Ecto.Types.MapSet do
  @moduledoc """
  Ecto type to persist MapSets of a given value type
  """
  use Ecto.ParameterizedType

  def type(%{type: :atom}), do: {:array, :string}
  def type(%{type: type}), do: {:array, type}

  def init(options) do
    %{type: Keyword.fetch!(options, :type)}
  end

  def cast(%MapSet{} = map_set, _params) do
    {:ok, map_set}
  end

  def cast(list, _params) when is_list(list) do
    {:ok, MapSet.new(list)}
  end

  def cast(_, _), do: :error

  def load(list, loader, params) when is_list(list) do
    load_inner_type(list, loader, params)
  end

  def dump(%MapSet{} = map_set, dumper, params) do
    dump_inner_type(map_set, dumper, params)
  end

  def dump(list, dumper, params) when is_list(list) do
    dump_inner_type(list, dumper, params)
  end

  def dump(_, _dumper, _params), do: :error

  def equal?(%MapSet{} = left, %MapSet{} = right, _params) do
    MapSet.equal?(left, right)
  end

  defp dump_inner_type(list_or_map_set, dumper, %{type: type}) do
    Enum.reduce_while(list_or_map_set, {:ok, []}, fn value, {:ok, acc} ->
      case apply_dumper(dumper, type, value) do
        {:ok, value} ->
          {:cont, {:ok, [value | acc]}}

        error ->
          {:halt, error}
      end
    end)
  end

  defp load_inner_type(list, loader, %{type: type}) do
    Enum.reduce_while(list, {:ok, MapSet.new()}, fn value, {:ok, acc} ->
      case apply_loader(loader, type, value) do
        {:ok, value} ->
          {:cont, {:ok, MapSet.put(acc, value)}}

        error ->
          {:halt, error}
      end
    end)
  end

  defp apply_dumper(_dumper, :atom, value), do: {:ok, to_string(value)}

  defp apply_dumper(dumper, type, value) do
    dumper.(type, value)
  end

  defp apply_loader(_loader, :atom, value) do
    {:ok, String.to_existing_atom(value)}
  rescue
    _ ->
      :error
  end

  defp apply_loader(loader, type, value), do: loader.(type, value)
end
