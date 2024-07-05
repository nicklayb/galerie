defmodule GalerieWeb.Router do
  use Phoenix.Router

  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  alias GalerieWeb.Plugs

  pipeline(:browser) do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {GalerieWeb.Components.Layouts, :root})
    plug(:put_layout, {GalerieWeb.Components.Layouts, :app})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline(:session_authenticated) do
    plug(Plugs.LoadUser)
    plug(Plugs.EnsureAuthenticated, authenticated: true)
  end

  pipeline(:session_offline) do
    plug(Plugs.LoadUser)
    plug(Plugs.EnsureAuthenticated, authenticated: false)
    plug(:put_layout, {GalerieWeb.Components.Layouts, :offline})
  end

  pipeline(:api) do
    plug(:accepts, ["json"])
  end

  scope("/app", GalerieWeb) do
    pipe_through([:browser, :session_authenticated])

    live_session(:session,
      on_mount: [GalerieWeb.Hooks.Authenticated, GalerieWeb.Hooks.UrlUpdated],
      layout: {GalerieWeb.Components.Layouts, :app},
      session: {GalerieWeb.Hooks.LiveSession, :session, []}
    ) do
      live("/", Library.Live)
    end
  end

  scope("/", GalerieWeb) do
    pipe_through([:browser, :session_authenticated])

    get("/pictures/:image", Library.Controller, :get)
  end

  scope("/", GalerieWeb) do
    pipe_through([:browser, :session_offline])

    get("/", Authentication.Controller, :login)
    get("/login", Authentication.Controller, :login)
    post("/login", Authentication.Controller, :post_login)

    get("/register", Authentication.Controller, :register)
    post("/register", Authentication.Controller, :post_register)

    get("/forgot_password", Authentication.Controller, :forgot_password)
    post("/forgot_password", Authentication.Controller, :post_forgot_password)

    get("/reset_password", Authentication.Controller, :reset_password)
    put("/reset_password", Authentication.Controller, :post_reset_password)
  end

  scope("/", GalerieWeb) do
    pipe_through([:browser])
    get("/logout", Authentication.Controller, :logout)
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope("/") do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: GalerieWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
