defmodule Galerie.Accounts.User.Permission do
  use Galerie.Accounts.Permission,
    permissions: [
      :upload_pictures,
      :create_album
    ]
end
