defmodule List.Extra do
  def at_least?(list, count) do
    at_least?(list, count, 0)
  end

  defp at_least?(_, count, current) when current >= count, do: true
  defp at_least?([], _, _), do: false
  defp at_least?([_ | rest], count, current), do: at_least?(rest, count, current + 1)
end
