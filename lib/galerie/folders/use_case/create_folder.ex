defmodule Galerie.Folders.UseCase.CreateFolder do
  @moduledoc """
  Use case that creates a global folder. Since user's
  folder are created in the `Accounts.UseCase.CreateUser`
  use case, this use case should be uesd *only* by file watcher
  to create locally sourced folders.
  """
  use Galerie.UseCase

  alias Galerie.Folders.Folder

  @impl Galerie.UseCase
  def validate(path, _options) do
    {:ok, %{path: path}}
  end

  @impl Galerie.UseCase
  def run(multi, params, _options) do
    Ecto.Multi.insert(multi, :folder, Folder.changeset(params))
  end

  @impl Galerie.UseCase
  def return(%{folder: folder}, _options) do
    folder
  end
end
