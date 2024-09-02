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

  def create_album(user, albums) when is_list(albums) do
    Enum.map(albums, &create_album(user, &1))
  end

  def create_album(user, album_name) do
    Albums.UseCase.CreateAlbum
    |> execute(%{name: album_name}, user)
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

Seed.create_album(main_user, ["Dogs", "Cats"])
