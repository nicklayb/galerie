defmodule Galerie.ObanRepo do
  use Ecto.Repo,
    otp_app: :galerie,
    adapter: Ecto.Adapters.Postgres
end
