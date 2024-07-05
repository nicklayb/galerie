defmodule GalerieWeb.Authentication.Controller do
  use Phoenix.Controller,
    namespace: GalerieWeb

  use GalerieWeb.Components.Routes

  import GalerieWeb.Gettext

  alias Galerie.Accounts
  alias Galerie.User
  alias GalerieWeb.Authentication

  action_fallback(Error.Controller)

  def login(conn, _params) do
    render(conn, "login.html", changeset: login_changeset())
  end

  def post_login(conn, %{"login_form" => %{"email" => email, "password" => password}}) do
    case Accounts.login(email, password) do
      {:ok, %User{} = user} ->
        conn
        |> Plug.Conn.clear_session()
        |> Authentication.login_user(user)
        |> Phoenix.Controller.redirect(to: ~p(/app/home))

      _ ->
        changeset =
          %{email: email}
          |> login_changeset()
          |> Map.put(:action, :insert)
          |> Ecto.Changeset.add_error(:email, "invalid email or password")

        render(conn, "login.html", changeset: changeset)
    end
  end

  def register(conn, _params) do
    render(conn, "register.html", changeset: register_changeset())
  end

  def post_register(conn, %{"register_form" => register_form}) do
    case Accounts.create_user(register_form) do
      {:ok, %User{} = user} ->
        conn
        |> Plug.Conn.clear_session()
        |> Authentication.login_user(user)
        |> Phoenix.Controller.redirect(to: ~p(/app/home))

      {:error, {:user, %Ecto.Changeset{} = changeset, _}} ->
        render(conn, "register.html", changeset: changeset)
    end
  end

  def forgot_password(conn, _params) do
    render(conn, "forgot_password.html", changeset: forgot_password_changeset())
  end

  def post_forgot_password(conn, %{"forgot_password_form" => %{"email" => email}}) do
    Accounts.reset_password(email)

    conn
    |> Phoenix.Controller.put_flash(
      :info,
      gettext(
        "If that email exist, you should receive an email with instruction to reset your password"
      )
    )
    |> render("forgot_password.html", changeset: forgot_password_changeset())
  end

  def reset_password(conn, params) do
    reset_password_token = Map.get(params, "token", "")

    case Accounts.get_user_by_reset_password_token(reset_password_token) do
      {:ok, %User{} = user} ->
        render(conn, "reset_password.html",
          changeset: reset_password_changeset(user),
          reset_password_token: reset_password_token
        )

      {:error, :not_found} ->
        conn
        |> Phoenix.Controller.put_flash(
          :error,
          gettext("This link either expired or is no longer valid")
        )
        |> Phoenix.Controller.redirect(to: ~p(/login/))
    end
  end

  def post_reset_password(conn, %{"token" => reset_password_token, "reset_password_form" => form}) do
    case Accounts.update_password(reset_password_token, form) do
      {:ok, %User{}} ->
        conn
        |> Phoenix.Controller.put_flash(
          :info,
          gettext("Password updated succesfully, you can now login")
        )
        |> Phoenix.Controller.redirect(to: ~p(/login))

      {:error, :not_found} ->
        conn
        |> Phoenix.Controller.put_flash(
          :info,
          gettext("This link either expired or is no longer valid")
        )
        |> Phoenix.Controller.redirect(to: ~p(/login))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "reset_password.html",
          changeset: changeset,
          reset_password_token: reset_password_token
        )
    end
  end

  def logout(conn, _) do
    conn
    |> Plug.Conn.clear_session()
    |> Phoenix.Controller.redirect(to: ~p(/))
    |> Plug.Conn.halt()
  end

  @types %{email: :string, password: :string}
  @permitted Map.keys(@types)
  defp login_changeset(params \\ %{}) do
    Ecto.Changeset.cast({%{}, @types}, params, @permitted)
  end

  @types %{email: :string}
  @permitted Map.keys(@types)
  defp forgot_password_changeset(params \\ %{}) do
    Ecto.Changeset.cast({%{}, @types}, params, @permitted)
  end

  defp reset_password_changeset(user, params \\ %{}) do
    User.update_password_changeset(user, params)
  end

  defp register_changeset(params \\ %{}) do
    User.changeset(params)
  end
end
