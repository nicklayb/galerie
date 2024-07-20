defmodule Galerie.Repo.Migrations.CreateFoldersTable do
  use Ecto.Migration

  def change do
    create(table("folders")) do
      add(:path, :string, null: false)
      add(:user_id, references("users", on_delete: :delete_all), null: true)

      timestamps()
    end

    create(unique_index("folders", [:path]))
    create(unique_index("folders", [:user_id]))
  end
end
