defmodule Galerie.Repo.Migrations.AddHideFromMainLibraryToAlbums do
  use Ecto.Migration

  def change do
    alter(table("albums")) do
      add(:hide_from_main_library, :boolean, null: false, default: false)
    end
  end
end
