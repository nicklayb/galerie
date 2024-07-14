defmodule Galerie.Accounts do
  alias Galerie.Accounts.User
  alias Galerie.Folders.Folder
  alias Galerie.Repo

  @doc "Logins a user"
  @spec login(User.email(), User.password()) :: Result.t(User.t(), :not_found)
  def login(email, password) do
    with {:ok, %User{password: password_hash} = user} <- get_user_by_email(email),
         true <- Argon2.verify_pass(password, password_hash) do
      {:ok, user}
    else
      _ ->
        Argon2.no_user_verify()
        {:error, :not_found}
    end
  end

  defp get_user_by_email(email), do: Repo.fetch_by(User, email: String.downcase(email))

  @doc "Gets a user by its reset password token"
  @spec get_user_by_reset_password_token(String.t()) :: Result.t(User.t(), :not_found)
  def get_user_by_reset_password_token(reset_password_token),
    do: Repo.fetch_by(User, reset_password_token: reset_password_token)

  @doc "Gets a user by id"
  @spec get_user_by_id(Repo.record_id()) :: Result.t(User.t(), :not_found)
  def get_user_by_id(id) do
    User
    |> Repo.fetch(id)
    |> Result.map(&Repo.preload(&1, [:folder]))
  end

  @doc "Creates a user"
  @spec create_user(map()) :: Result.t(User.t(), any())
  def create_user(params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:initial_user, User.changeset(%User{}, params))
    |> Ecto.Multi.insert(:folder, fn %{initial_user: user} ->
      folder_path =
        user
        |> Galerie.Directory.upload("tmp.jpg")
        |> Path.dirname()

      Folder.changeset(%Folder{}, %{path: folder_path})
    end)
    |> Ecto.Multi.update(:user, fn %{initial_user: user, folder: %Folder{id: folder_id}} ->
      Ecto.Changeset.cast(user, %{folder_id: folder_id}, [:folder_id])
    end)
    |> Repo.transaction()
    |> Result.tap(fn %{user: user} ->
      Galerie.Mailer.deliver_async(fn ->
        Galerie.Mailer.welcome(user)
      end)
    end)
  end

  @doc "Resets a user password"
  @spec reset_password(User.t() | String.t()) :: Result.t(User.t(), any())
  def reset_password(%User{} = user) do
    user
    |> User.reset_password_changeset()
    |> Repo.update()
    |> Result.tap(fn user ->
      Galerie.Mailer.deliver_async(fn ->
        Galerie.Mailer.reset_password(user)
      end)
    end)
  end

  def reset_password(email) do
    with {:ok, %User{} = user} <- get_user_by_email(email) do
      reset_password(user)
    end
  end

  def update_password(%User{} = user, params) do
    user
    |> User.update_password_changeset(params)
    |> Repo.update()
  end

  def update_password(reset_password_token, params) do
    with {:ok, %User{} = user} <- get_user_by_reset_password_token(reset_password_token) do
      update_password(user, params)
    end
  end
end
