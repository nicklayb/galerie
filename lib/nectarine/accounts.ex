defmodule Nectarine.Accounts do
  alias Nectarine.Repo
  alias Nectarine.User

  @doc "Logins a user"
  @spec login(User.email(), User.password()) :: Result.t(User.t(), :not_found)
  def login(email, password) do
    with {:ok, %User{password: password_hash} = user} <- get_user_by_email(email),
         true <- Argon2.verify_pass(password, password_hash) do
      {:ok, user}
    else
      {:error, :not_found} ->
        Argon2.no_user_verify()
        {:error, :not_found}

      _ ->
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
  def get_user_by_id(id), do: Repo.fetch(User, id)

  @doc "Creates a user"
  @spec create_user(map()) :: Result.t(User.t(), any())
  def create_user(params) do
    Nectarine.User
    |> Nectarine.GearboxApplication.dispatch({:create, params}, nil)
    |> Repo.unwrap_transaction(:user)
  end

  @doc "Resets a user password"
  @spec reset_password(User.t() | String.t()) :: Result.t(User.t(), any())
  def reset_password(%User{} = user) do
    Nectarine.User
    |> Nectarine.GearboxApplication.dispatch({:reset_password, user}, nil)
    |> Repo.unwrap_transaction(:user)
  end

  def reset_password(email) do
    with {:ok, %User{} = user} <- get_user_by_email(email) do
      reset_password(user)
    end
  end

  def update_password(%User{} = user, params) do
    Nectarine.User
    |> Nectarine.GearboxApplication.dispatch({:update_password, user, params}, nil)
    |> Repo.unwrap_transaction(:user)
  end

  def update_password(reset_password_token, params) do
    with {:ok, %User{} = user} <- get_user_by_reset_password_token(reset_password_token) do
      update_password(user, params)
    end
  end
end
