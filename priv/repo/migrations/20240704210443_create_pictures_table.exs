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
      add(:group_name, :string, null: false)
      add(:type, :picture_type)

      add(:thumbnail, :string, null: true)
      add(:converted_jpeg, :string, null: true)

      add(:folder_id, references("folders", on_delete: :delete_all), null: false)
      add(:user_id, references("users", on_delete: :delete_all), null: true)

      timestamps()
    end

    create(index("pictures", :group_name))
    create(index("pictures", :original_name))
    create(index("pictures", :folder_id))
    create(index("pictures", :user_id))
    create(unique_index("pictures", :fullpath))
    create(unique_index("pictures", [:original_name, :folder_id]))
  end
end
