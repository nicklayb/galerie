defmodule BinaryFlags do
  import Bitwise

  @type flag :: atom()
  @type flags :: [flag()]
  @type raw :: non_neg_integer()

  @spec to_integer(flags(), flags()) :: raw()
  def to_integer(available_flags, flags) when is_list(flags) do
    available_flags
    |> Enum.reverse()
    |> Enum.reduce(0, fn flag, acc ->
      new_acc = acc <<< 1

      if flag in flags do
        new_acc + 1
      else
        new_acc
      end
    end)
  end

  @spec to_flags(flags(), flags() | raw()) :: flags()
  def to_flags(available_flags, list) when is_list(list) do
    Enum.reject(list, &(&1 not in available_flags))
  end

  def to_flags(available_flags, integer)
      when is_integer(integer) and integer >= 0 do
    {flags, _} =
      Enum.reduce(available_flags, {[], 1}, fn flag, {acc, current_binary} ->
        new_binary = current_binary <<< 1

        if Bitwise.band(integer, current_binary) > 0 do
          {[flag | acc], new_binary}
        else
          {acc, new_binary}
        end
      end)

    flags
  end

  def to_flags(_avilable_flags, integer) when is_integer(integer), do: []
end
