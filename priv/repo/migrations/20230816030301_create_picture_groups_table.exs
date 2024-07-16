defmodule Galerie.Repo.Migrations.CreatePictureGroupsTable do
  use Ecto.Migration

  def change do
    create(table("picture_groups")) do
      add(:name, :string, null: false)
      add(:group_name, :string, null: false)
      add(:folder_id, references("folders", on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index("picture_groups", [:folder_id, :group_name]))
  end
end
