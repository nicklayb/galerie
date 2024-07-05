defmodule Galerie.Repo.Migrations.CreatePictureMetadataTable do
  use Ecto.Migration

  @enum_name :picture_orientation
  @create_query "CREATE TYPE #{@enum_name} AS ENUM ('landscape', 'portrait')"
  @drop_query "DROP TYPE #{@enum_name}"
  def change do
    execute(@create_query, @drop_query)
    create(table("picture_metadata")) do
      add(:picture_id, references("pictures", on_delete: :delete_all), null: false)
      add(:exposure_time, :float)
      add(:f_number, :float)
      add(:focal_length, :float)
      add(:lens_model, :string)
      add(:make, :string)
      add(:datetime_original, :naive_datetime)
      add(:longitude, :float)
      add(:latitude, :float)
      add(:width, :integer)
      add(:height, :integer)
      add(:orientation, @enum_name)
      
      timestamps()
    end

    create(unique_index("picture_metadata", :picture_id))
  end
end
