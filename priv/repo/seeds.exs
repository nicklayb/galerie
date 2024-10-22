alias Galerie.Accounts
alias Galerie.Albums

Galerie.Repo.start_link([])
Task.Supervisor.start_link(name: Galerie.MailerSupervisor)

defmodule Seed do
  def create_user(users) when is_list(users) do
    Enum.map(users, &create_user/1)
  end

  @password "admin"
  def create_user(user_params) do
    params = Map.merge(user_params, %{password: @password, password_confirmation: @password})

    Accounts.UseCase.CreateUser
    |> execute(params)
    |> Result.unwrap!()
  end

  def create_album_folder(user, name, parent_folder_id \\ nil) do
    Albums.UseCase.CreateAlbumFolder
    |> execute(%{name: name, parent_folder_id: parent_folder_id}, user)
    |> Result.unwrap!()
  end

  def create_album(user, albums, attributes \\ %{})

  def create_album(user, albums, attributes) when is_list(albums) do
    Enum.map(albums, &create_album(user, &1, attributes))
  end

  def create_album(user, album_name, attributes) do
    Albums.UseCase.CreateAlbum
    |> execute(Map.merge(attributes, %{name: album_name}), user)
    |> Result.unwrap!()
  end

  defp execute(use_case, params, user \\ :system) do
    use_case.execute(params, user: user, after_run?: false)
  end
end

[main_user] =
  Seed.create_user([
    %{first_name: "John", last_name: "Doe", email: "admin@example.com", is_admin: true}
  ])

animals_folder = Seed.create_album_folder(main_user, "Animals")
cats_folder = Seed.create_album_folder(main_user, "Cats", animals_folder.id)
dogs_folder = Seed.create_album_folder(main_user, "Dogs", animals_folder.id)

Seed.create_album(main_user, ["Louise", "Lili"], %{album_folder_id: cats_folder.id})
Seed.create_album(main_user, ["Marcus"], %{album_folder_id: dogs_folder.id})
Seed.create_album(main_user, ["Other"], %{album_folder_id: animals_folder.id})
Seed.create_album(main_user, ["Family photos", "Friends"])
