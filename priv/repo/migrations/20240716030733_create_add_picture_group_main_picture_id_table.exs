defmodule Galerie.Repo.Migrations.CreateAddPictureGroupMainPictureIdTable do
  use Ecto.Migration

  def change do
    alter(table("picture_groups")) do
      add(:main_picture_id, references("pictures", on_delete: :delete_all))
    end

    create(unique_index("picture_groups", :main_picture_id))
  end
end
