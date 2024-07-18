defmodule Galerie.Repo.Migrations.CreateFractionType do
  use Ecto.Migration

  def up do
    execute """
    CREATE TYPE public.fraction AS (numerator int, denominator int)
    """
  end

  def down do
    execute """
    DROP TYPE public.fraction
    """
  end
end
