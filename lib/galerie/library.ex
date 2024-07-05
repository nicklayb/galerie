defmodule Galerie.Library do
  alias Galerie.Picture
  alias Galerie.Repo

  def get_picture(picture_id) do
    Repo.fetch(Picture, picture_id)
  end

  def get_picture_by_path(path) do
    Repo.fetch_by(Picture, fullpath: path)
  end
end
