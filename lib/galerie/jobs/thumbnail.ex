defmodule Galerie.Jobs.Thumbnail do
  alias Galerie.Picture

  def enqueue(%Picture{type: :tiff} = picture) do
    Galerie.Jobs.ThumbnailGenerator.Tiff.enqueue(picture)
  end

  def enqueue(%Picture{type: :jpeg} = picture) do
    Galerie.Jobs.ThumbnailGenerator.Jpeg.enqueue(picture)
  end
end
