defmodule Galerie.Repo.Migrations.CreateAlbums do
  use Ecto.Migration

  def change do
    create(table("albums")) do
      add(:user_id, references("users", on_delete: :delete_all), null: false)
      add(:name, :string, null: false)

      timestamps()
    end

    create(table("albums_picture_groups")) do
      add(:album_id, references("albums", on_delete: :delete_all), null: false)
      add(:group_id, references("picture_groups", on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index("albums", [:user_id, :name]))
    create(unique_index("albums_picture_groups", [:album_id, :group_id]))
  end
end
