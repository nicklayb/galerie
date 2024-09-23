defmodule GalerieWeb.Settings.Users.Index do
  use GalerieWeb, {:live_view, layout: :settings}

  alias Galerie.Accounts.User
  alias Galerie.Repo

  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Components.Table

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Users"))
      |> assign_async(:users, fn -> {:ok, %{users: load_users()}} end)

    {:ok, socket}
  end

  defp load_users do
    User
    |> Repo.paginate()
  end
end
