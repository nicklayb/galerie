defmodule Galerie.Jobs.Thumbnail do
  alias Galerie.Picture

  def enqueue(%Picture{type: :tiff} = picture) do
    Galerie.Jobs.TiffThumbnailGenerator.enqueue(picture)
  end

  def enqueue(%Picture{type: :jpeg} = picture) do
    Galerie.Jobs.ThumbnailGenerator.enqueue(picture)
  end
end
