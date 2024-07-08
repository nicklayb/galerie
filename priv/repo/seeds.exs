alias Galerie.Accounts

Galerie.Repo.start_link([])
Task.Supervisor.start_link(name: Galerie.MailerSupervisor)

defmodule Seed do
  def create_user(users) when is_list(users) do
    Enum.map(users, &create_user/1)
  end

  @password "Shawi1234"
  def create_user(user_params) do
    user_params
    |> Map.merge(%{password: @password, password_confirmation: @password})
    |> Accounts.create_user()
    |> Result.unwrap!()
  end
end

[_nicolas] =
  Seed.create_user([
    %{first_name: "Nicolas", last_name: "Boisvert", email: "nicklay@me.com"}
  ])
