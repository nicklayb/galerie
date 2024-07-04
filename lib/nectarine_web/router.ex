defmodule NectarineWeb.Router do
  use Phoenix.Router

  import Plug.Conn
  import Phoenix.Controller
  import Phoenix.LiveView.Router

  alias NectarineWeb.Plugs

  pipeline(:browser) do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {NectarineWeb.Components.Layouts, :root})
    plug(:put_layout, {NectarineWeb.Components.Layouts, :app})
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
    plug(:put_layout, {NectarineWeb.Components.Layouts, :offline})
  end

  pipeline(:api) do
    plug(:accepts, ["json"])
  end

  scope("/app", NectarineWeb) do
    pipe_through([:browser, :session_authenticated])

    live_session(:session,
      on_mount: [NectarineWeb.Hooks.Authenticated, NectarineWeb.Hooks.UrlUpdated],
      layout: {NectarineWeb.Components.Layouts, :app},
      session: {NectarineWeb.Hooks.LiveSession, :session, []}
    ) do
      live("/home", Home.Live)
    end
  end

  scope("/", NectarineWeb) do
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

  scope("/", NectarineWeb) do
    pipe_through([:browser])
    get("/logout", Authentication.Controller, :logout)
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope("/") do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: NectarineWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
