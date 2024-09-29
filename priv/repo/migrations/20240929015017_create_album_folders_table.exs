defmodule Galerie.Repo.Migrations.CreateAlbumFoldersTable do
  use Ecto.Migration

  def change do
    create(table("album_folders")) do
      add(:user_id, references("users", on_delete: :delete_all), null: false)
      add(:name, :string, null: false)
    end

    alter(table("albums")) do
      add(:album_folder_id, references("album_folders", on_delete: :nilify_all), null: true)
    end

    alter(table("album_folders")) do
      add(:parent_folder_id, references("album_folders", on_delete: :nilify_all), null: true)
    end

    create(unique_index("album_folders", [:parent_folder_id, :name]))
    create(index("album_folders", [:user_id]))
  end
end
