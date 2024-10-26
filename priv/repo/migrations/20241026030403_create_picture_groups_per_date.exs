defmodule Galerie.Repo.Migrations.CreatePictureGroupsPerDate do
  use Ecto.Migration

  def change do
    create(table("picture_groups_per_date")) do
      add(:date, :date, null: false)
      add(:count, :integer, null: false)
      add(:folder_id, references("folders", on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index("picture_groups_per_date", [:date, :folder_id]))
  end
end
