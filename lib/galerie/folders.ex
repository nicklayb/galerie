defmodule Galerie.Folders do
  alias Galerie.Accounts.User
  alias Galerie.Folders.Folder
  alias Galerie.Folders.UseCase
  alias Galerie.Repo

  def get_user_folders(%User{} = user) do
    user
    |> Folder.Query.by_user()
    |> Repo.all()
  end

  def get_or_create_folder!(folder_path, options \\ []) do
    case Repo.fetch_by(Folder, path: folder_path) do
      {:ok, %Folder{} = folder} ->
        folder

      _ ->
        Galerie.UseCase.execute!(UseCase.CreateFolder, folder_path, options)
    end
  end
end
