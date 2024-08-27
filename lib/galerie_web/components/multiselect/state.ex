defmodule GalerieWeb.Components.Multiselect.State do
  defstruct [:id, :options, selected: [], count: 0, type: :any]

  alias GalerieWeb.Components.Multiselect.Options
  alias GalerieWeb.Components.Multiselect.State

  def new(options_key) when is_atom(options_key) or is_tuple(options_key) do
    options = Options.build(options_key)
    %State{id: Ecto.UUID.generate(), options: options, type: options_key}
  end

  def update(%State{type: options_key} = state) do
    new_options = Options.build(options_key)

    reject_missing_options(%State{state | options: new_options})
  end

  defp reject_missing_options(%State{selected: selected} = state) do
    new_selected =
      Enum.reduce(selected, [], fn selected_value, acc ->
        if option_exists?(state, selected_value) do
          [selected_value | acc]
        else
          acc
        end
      end)

    update(state, Enum.reverse(new_selected))
  end

  defp option_exists?(%State{options: options}, value) do
    Enum.any?(options, fn {_, key, _} -> key == value end)
  end

  def all(%State{options: options} = state) do
    items = Enum.map(options, fn {_, key, _} -> key end)

    update(state, items)
  end

  def clear(%State{} = state), do: update(state, [])

  def update(%State{} = state, items) do
    %State{state | selected: items, count: length(items)}
  end

  def selected?(%State{selected: selected}, item), do: item in selected

  def selected_items(%State{selected: selected, options: options}) do
    options
    |> Enum.reduce([], fn {original, key, _}, acc ->
      if key in selected, do: [original | acc], else: acc
    end)
    |> Enum.reverse()
  end
end
