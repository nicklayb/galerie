defmodule Galerie.Folders do
  require Ecto.Query
  alias Galerie.Accounts.User
  alias Galerie.Folders.Folder
  alias Galerie.Repo

  def get_user_folders(%User{} = user) do
    user
    |> Folder.Query.by_user()
    |> Repo.all()
  end

  def get_or_create_folder!(folder_path) do
    case Repo.fetch_by(Folder, path: folder_path) do
      {:ok, %Folder{} = folder} ->
        folder

      _ ->
        %{path: folder_path, global: true}
        |> Folder.changeset()
        |> Repo.insert!()
    end
  end
end
