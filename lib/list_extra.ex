defmodule List.Extra do
  @moduledoc """
  Helper functions to work with List.
  """

  @doc """
  Returns true if the list as at least `count` elements, we
  are using list pattern match in order to make sure that whole
  list is not crawled.
  """
  @spec at_least?(list(), non_neg_integer()) :: boolean()
  def at_least?(list, count) do
    at_least?(list, count, 0)
  end

  defp at_least?(_, count, current) when current >= count, do: true
  defp at_least?([], _, _), do: false
  defp at_least?([_ | rest], count, current), do: at_least?(rest, count, current + 1)
end
