defmodule Galerie.Repo.Migrations.AddMetadataUpdatedFields do
  use Ecto.Migration

  def change do
    alter(table("picture_metadata")) do
      add(:manually_updated_fields, {:array, :string}, null: false, default: [])
    end
  end
end
