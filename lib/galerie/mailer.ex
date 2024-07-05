defmodule Galerie.Mailer do
  use Swoosh.Mailer, otp_app: :galerie
  use GalerieWeb.Components.Routes
  import Swoosh.Email

  import GalerieWeb.Gettext
  alias Galerie.User

  @task_supervisor_name Galerie.MailerSupervisor

  def deliver_async(builder_function, config \\ []) do
    Task.Supervisor.start_child(@task_supervisor_name, fn ->
      case builder_function.() do
        list when is_list(list) ->
          deliver_many(list, config)

        email ->
          deliver(email, config)
      end
    end)
  end

  def welcome(%User{} = user) do
    new()
    |> to(user)
    |> from_galerie()
    |> subject(gettext("Welcome to Galerie"))
    |> html_body("<h1>Welcome #{user.first_name}</h1>")
    |> text_body("Welcome #{user.first_name}")
  end

  def reset_password(%User{} = user) do
    new()
    |> to(user)
    |> from_galerie()
    |> subject(gettext("Reset password request"))
    |> html_body("""
    <h1>Reset password requested</h1>
    <p>A reset password was requested for your email. Follow the link below to reset it.</p>
    <a href=#{url(~p(/reset_password?#{[token: user.reset_password_token]}))}>Reset password</a>
    <p>If you did not request this, please ignore</p>
    """)
    |> text_body("""
    Reset password requested

    A reset password was requested for your email. Follow the link below to reset it.

    #{url(~p(/reset_password?#{[token: user.reset_password_token]}))}

    If you did not request this, please ignore
    """)
  end

  defp from_galerie(mail), do: from(mail, mailer_from())

  defp mailer_from, do: Application.get_env(:galerie, Galerie.Mailer)[:mailer_from]
end
