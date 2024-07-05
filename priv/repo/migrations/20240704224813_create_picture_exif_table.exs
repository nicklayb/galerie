defmodule Galerie.Repo.Migrations.CreatePictureExifTable do
  use Ecto.Migration

  def change do
    create(table("picture_exif")) do
      add(:picture_id, references("pictures", on_delete: :delete_all), null: false)
      
      add(:exif, :json, null: false)

      timestamps()
    end

    create(unique_index("picture_exif", :picture_id))
  end
end
