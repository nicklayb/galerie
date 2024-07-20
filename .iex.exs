alias Galerie.Accounts
alias Galerie.Accounts.User
alias Galerie.Albums
alias Galerie.Albums.Album
alias Galerie.Albums.AlbumPictureGroup
alias Galerie.Folders
alias Galerie.Folders.Folder
alias Galerie.Pictures
alias Galerie.Pictures.Picture
alias Galerie.Pictures.Picture.Exif, as: PictureExif
alias Galerie.Pictures.Picture.Group, as: PictureGroup
alias Galerie.Pictures.Picture.Metadata, as: PictureMetadata
alias Galerie.Repo

defmodule Dev do
  def user, do: Galerie.Repo.first(Galerie.Accounts.User)
  def folders, do: Galerie.Repo.all(Galerie.Folders.Folder)
end

import Ecto.Query

IO.puts(~s(

  >>= Galerie

))
