defmodule Galerie.Repo.Migrations.AddRatingToPictureGroups do
  use Ecto.Migration

  def change do
    alter(table("picture_groups")) do
      add(:rating, :smallint, null: true)
    end
  end
end
