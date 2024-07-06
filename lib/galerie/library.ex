defmodule Galerie.Library do
  alias Galerie.Picture
  alias Galerie.Repo

  @spec list_pictures(Keyword.t()) :: Repo.Page.t()
  def list_pictures(_) do
    Repo.paginate(Picture, %{limit: 30})
  end

  @spec get_picture(String.t()) :: Result.t(Picture.t(), :not_found)
  def get_picture(picture_id) do
    Repo.fetch(Picture, picture_id)
  end

  @spec get_picture(String.t()) :: Result.t(Picture.t(), :not_found)
  def get_picture_by_path(path) do
    Repo.fetch_by(Picture, fullpath: path)
  end
end
