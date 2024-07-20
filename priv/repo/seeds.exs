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
    user_params
    |> Map.merge(%{password: @password, password_confirmation: @password})
    |> Accounts.create_user(after_run?: false)
    |> Result.unwrap!()
  end

  def create_album(user, albums) when is_list(albums) do
    Enum.map(albums, &create_album(user, &1))
  end

  def create_album(user, album_name) do
    user
    |> Albums.create_album(%{name: album_name}, after_run?: false)
    |> Result.unwrap!()
  end
end

[main_user] =
  Seed.create_user([
    %{first_name: "John", last_name: "Doe", email: "admin@example.com", is_admin: true}
  ])

[_, _, _] =
  Seed.create_album(main_user, [
    "First album",
    "Second album",
    "Third album"
  ])
