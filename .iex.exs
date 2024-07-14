alias Galerie.Accounts
alias Galerie.Accounts.User
alias Galerie.Albums
alias Galerie.Albums.Album
alias Galerie.Pictures
alias Galerie.Pictures.Picture
alias Galerie.Pictures.PictureExif
alias Galerie.Pictures.PictureMetadata
alias Galerie.Repo

defmodule Dev do
  def user, do: Galerie.Repo.first(Galerie.Accounts.User)
end

import Ecto.Query

IO.puts(~s(

  >>= Galerie

))
