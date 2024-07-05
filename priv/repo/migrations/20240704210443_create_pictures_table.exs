defmodule Galerie.Repo.Migrations.CreatePicturesTable do
  use Ecto.Migration

  @picture_type :picture_type
  @create_query "CREATE TYPE #{@picture_type} AS ENUM ('tiff', 'jpeg')"
  @drop_query "DROP TYPE #{@picture_type}"

  def change do
    execute(@create_query, @drop_query)
    create(table("pictures")) do
      add(:name, :string, null: false)
      add(:extension, :string, null: false)
      add(:original_name, :string, null: false)
      add(:size, :bigint, null: false)
      add(:fullpath, :string, null: false)
      add(:type, :picture_type)

      add(:thumbnail, :string, null: true)
      add(:converted_jpeg, :string, null: true)

      timestamps()
    end

    create(unique_index("pictures", :fullpath))
  end
end
