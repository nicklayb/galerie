defmodule GalerieWeb.Settings.Users.Index do
  use GalerieWeb, {:live_view, layout: :settings}

  alias Galerie.Accounts.User

  """

  <!-- <Table.render rows={@rows} let={user}> -->
  <!--   <:cell header={gettext("Name")}> -->
  <!--     <%= User.fullname(user) %> -->
  <!--   </:cell> -->
  <!-- </Table.render> -->
  """

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Users"))
      |> assign_async(:users, fn -> load_users() end)

    {:ok, socket}
  end

  defp load_users do
    User
    |> Repo.paginate()
  end
end
