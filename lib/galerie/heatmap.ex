defmodule Galerie.Heatmap do
  defstruct [:scale, values: %{}, mapped_values: %{}]

  alias Galerie.Heatmap

  def new(scale) do
    %Heatmap{scale: scale}
  end

  def new(scale, values) do
    scale
    |> new()
    |> put_values(values)
  end

  def get(%Heatmap{mapped_values: values}, key, default \\ 0) do
    Map.get(values, key, default)
  end

  def put_values(%Heatmap{} = heatmap, values) do
    mapped_values = map_values(heatmap, values)

    %Heatmap{heatmap | values: values, mapped_values: mapped_values}
  end

  def filter(%Heatmap{values: values} = heatmap, function) do
    filtered_values =
      Enum.reduce(values, %{}, fn {key, value}, acc ->
        if function.(key, value) do
          Map.put(acc, key, value)
        else
          acc
        end
      end)

    put_values(heatmap, filtered_values)
  end

  defp map_values(%Heatmap{scale: scale}, values) do
    with true <- Enum.any?(values),
         {_, maximum} when maximum > 0 <- Enum.max_by(values, fn {_, value} -> value end) do
      Enum.reduce(values, %{}, fn {key, value}, acc ->
        scaled_value =
          if value == 0 do
            0
          else
            ceil(scale * value / maximum)
          end

        Map.put(acc, key, scaled_value)
      end)
    else
      _ -> %{}
    end
  end
end
