defmodule Galerie.Accounts do
  alias Galerie.Accounts.UseCase
  alias Galerie.Accounts.User
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
  @spec create_user(map(), Keyword.t()) :: Result.t(User.t(), any())
  def create_user(params, options \\ []) do
    UseCase.CreateUser.execute(params, options)
  end

  @doc "Resets a user password"
  @spec reset_password(User.t() | String.t(), Keyword.t()) :: Result.t(User.t(), any())

  def reset_password(email, options \\ [])

  def reset_password(%User{} = user, options) do
    UseCase.ResetPassword.execute(user, options)
  end

  def reset_password(email, options) do
    with {:ok, %User{} = user} <- get_user_by_email(email) do
      reset_password(user, options)
    end
  end

  def update_password(user, params, options \\ [])

  def update_password(%User{} = user, params, options) do
    UseCase.UpdatePassword.execute({user, params}, options)
  end

  def update_password(reset_password_token, params, options) do
    with {:ok, %User{} = user} <- get_user_by_reset_password_token(reset_password_token) do
      update_password(user, params, options)
    end
  end
end
