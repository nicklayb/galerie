defmodule Galerie.Repo.Migrations.CreateAlbums do
  use Ecto.Migration

  def change do
    create(table("albums")) do
      add(:user_id, references("users", on_delete: :delete_all), null: false)
      add(:name, :string, null: false)
    end

    create(table("albums_pictures")) do
      add(:album_id, references("albums", on_delete: :delete_all), null: false)
      add(:picture_id, references("pictures", on_delete: :delete_all), null: false)
    end

    create(unique_index("albums", [:user_id, :name]))
    create(unique_index("albums_pictures", [:album_id, :picture_id]))
  end
end
