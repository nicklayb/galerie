defmodule GalerieWeb.Components.Multiselect.Options do
  import GalerieWeb.Gettext

  alias Galerie.Pictures
  alias Galerie.Pictures.Picture.Group

  @type t :: {any(), String.t(), String.t()}

  def build(:rating) do
    ratings =
      Enum.map(Group.rating_range(), &{&1, to_string(&1), gettext("%{count} star", count: &1)})

    [{:empty, "empty", gettext("Unrated")} | ratings]
  end

  def build({:metadata, :exposure_time}) do
    :exposure_time
    |> Pictures.distinct_metadata()
    |> Enum.sort({:desc, Fraction})
    |> Enum.map(fn fraction ->
      {fraction, Fraction.to_string(fraction), Fraction.to_string(fraction)}
    end)
  end

  def build({:metadata, metadata}) do
    metadata
    |> Pictures.distinct_metadata()
    |> build()
  end

  def build(list) when is_list(list) do
    Enum.map(list, &{&1, to_string(&1), &1})
  end
end
