defmodule Galerie.Folders do
  alias Galerie.Folders.Folder
  alias Galerie.Repo

  def get_or_create_folder!(folder_path) do
    case Repo.fetch_by(Folder, path: folder_path) do
      {:ok, %Folder{} = folder} ->
        folder

      _ ->
        %{path: folder_path}
        |> Folder.changeset()
        |> Repo.insert!()
    end
  end
end
