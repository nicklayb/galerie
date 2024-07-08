defmodule Galerie.Repo.Migrations.CreateFoldersTable do
  use Ecto.Migration

  def change do
    create(table("folders")) do
      add(:path, :string, null: false)

      timestamps()
    end

    create(unique_index("folders", [:path]))
  end
end
