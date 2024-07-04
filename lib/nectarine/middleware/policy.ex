defmodule Nectarine.Middleware.Policy do
  @moduledoc """
  Policy middleware that ensure a user can perform certains actions
  """
  alias Nectarine.User

  require Ecto.Query

  @behaviour Gearbox.Middleware
  def run({User, _}, %{user_id: user_id}) when not is_nil(user_id) do
    {:abort, :already_logged_in}
  end

  def run({User, _}, _), do: :continue

  def run(_, _), do: {:abort, :not_allowed}
end
