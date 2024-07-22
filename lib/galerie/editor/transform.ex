defmodule Galerie.Editor.Transform do
  @type image :: Vix.Vips.Image.t()
  @type transformation :: {:rotate, integer()}

  def transform(%Vix.Vips.Image{} = image, {:rotate, degree}) do
    Image.rotate(image, degree)
  end
end
