defmodule Galerie.ObanRepo do
  use Ecto.Repo,
    otp_app: :galerie,
    adapter: Ecto.Adapters.Postgres

  require Ecto.Query

  def pending_jobs do
    Oban.Job
    |> Ecto.Query.where([job], job.state in ~w(retryable available executing))
    |> Ecto.Query.group_by([job], [job.state])
    |> Ecto.Query.select([job], {job.state, count("*")})
    |> all()
  end
end
