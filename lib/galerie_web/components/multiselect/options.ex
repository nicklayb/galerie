defmodule GalerieWeb.Components.Multiselect.Options do
  import GalerieWeb.Gettext

  alias Galerie.Pictures
  alias Galerie.Pictures.Picture.Group

  @type t :: {any(), String.t(), String.t()}

  @rating_range Group.rating_range()
  def build(items, options \\ [])

  def build(:rating, _options) do
    @rating_range
    |> Enum.map(&{&1, to_string(&1), gettext("%{count} star", count: &1)})
    |> with_empty(true, gettext("Unrated"))
  end

  def build({:metadata, :exposure_time}, _options) do
    {maybe_empty, items} =
      :exposure_time
      |> Pictures.distinct_metadata()
      |> Enum.split_with(&is_nil/1)

    items
    |> Enum.sort({:desc, Fraction})
    |> Enum.map(fn fraction ->
      {fraction, Fraction.to_string(fraction), Fraction.to_string(fraction)}
    end)
    |> with_empty(maybe_empty)
  end

  def build({:metadata, metadata}, options) do
    metadata
    |> Pictures.distinct_metadata()
    |> build(options)
  end

  def build(list, _options) when is_list(list) do
    {maybe_empty, items} = Enum.split_with(list, &is_nil/1)

    items
    |> Enum.map(&{&1, to_string(&1), &1})
    |> with_empty(maybe_empty)
  end

  defp with_empty(items, boolean, label \\ gettext("Empty"))
  defp with_empty(items, [_ | _], label), do: with_empty(items, true, label)
  defp with_empty(items, [], label), do: with_empty(items, false, label)
  defp with_empty(items, true, label), do: [{:empty, "empty", label} | items]
  defp with_empty(items, false, _), do: items
end
