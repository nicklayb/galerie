defmodule Galerie.Accounts.UseCase.CreateUser do
  use Galerie.UseCase

  alias Galerie.Accounts.User
  alias Galerie.Folders.Folder

  @impl Galerie.UseCase
  def run(multi, params, _options) do
    multi
    |> Ecto.Multi.insert(:user, User.changeset(%User{}, params))
    |> Ecto.Multi.insert(:folder, fn %{user: user} ->
      folder_path =
        user
        |> Galerie.Directory.upload("tmp.jpg")
        |> Path.dirname()

      Folder.changeset(%Folder{}, %{path: folder_path, user_id: user.id})
    end)
  end

  @impl Galerie.UseCase
  def after_run(%{user: user}, _options) do
    Galerie.Mailer.deliver_async(fn ->
      Galerie.Mailer.welcome(user)
    end)
  end

  @impl Galerie.UseCase
  def return(%{user: user}, _options), do: user
end
