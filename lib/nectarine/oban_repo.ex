defmodule Nectarine.ObanRepo do
  use Ecto.Repo,
    otp_app: :nectarine,
    adapter: Ecto.Adapters.Postgres
end
