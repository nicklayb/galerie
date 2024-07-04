defmodule NectarineWeb.Components.Layouts do
  use Phoenix.Component
  use NectarineWeb.Components.Routes
  alias NectarineWeb.Components.Ui
  alias Phoenix.LiveView.JS

  alias Nectarine.User

  embed_templates("layouts/*")

  def profile_dropdown(assigns) do
    # TOUDOU: make a generic dropdown component
    ~H"""
      <div class="relative">
        <button
          id="profile-dropdown"
          type="button"
          class="-m-1.5 flex items-center p-1.5"
          aria-expanded="false"
          aria-haspopup="true"
          phx-click={show_dropdown("#profile-dropdown-menu")}
        >
          <span class="sr-only">Open user menu</span>
          <span class="flex">
            <span class="ml-4 text-sm font-semibold leading-6 hover:text-purple-400" aria-hidden="true"><%= User.initials(@current_user) %></span>
            <svg class="ml-2 h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd" />
            </svg>
          </span>
        </button>

        <div
          id="profile-dropdown-menu"
          phx-click-away={hide_dropdown("#profile-dropdown-menu")}
          class="hidden absolute right-0 z-10 mt-2.5 w-32 origin-top-right rounded bg-true-gray-900 py-2 shadow-lg ring-1 ring-true-gray-300 focus:outline-none"
          role="menu"
          aria-orientation="vertical"
          aria-labelledby="user-menu-button"
          tabindex="-1"
        >
          <a href="#" class="block px-3 py-1 text-sm leading-6 text-true-gray-100 hover:bg-true-gray-800/40 hover:text-purple-400" role="menuitem" tabindex="-1" id="user-menu-item-0">Your profile</a>
          <a href="/logout" class="block px-3 py-1 text-sm leading-6 text-true-gray-100 hover:bg-true-gray-800/40 hover:text-purple-400" role="menuitem" tabindex="-1" id="user-menu-item-1">Sign out</a>
        </div>
      </div>
    """
  end

  def show_dropdown(to) do
    [
      to: to,
      transition:
        {"transition ease-out duration-120", "transform opacity-0 scale-95",
         "transform opacity-100 scale-100"}
    ]
    |> JS.show()
    |> JS.set_attribute({"aria-expanded", "true"}, to: to)
  end

  def hide_dropdown(to) do
    [
      to: to,
      transition:
        {"transition ease-in duration-120", "transform opacity-100 scale-100",
         "transform opacity-0 scale-95"}
    ]
    |> JS.hide()
    |> JS.remove_attribute("aria-expanded", to: to)
  end

  @default "flex flex-col bg-gray-200 border-l-4 py-3 px-2 mb-2 rounded-r-md"
  @class %{
    info: "#{@default} border-yellow-600 text-gray-800",
    error: "#{@default} border-red-800 text-gray-800"
  }
  attr(:message, :string, required: true)
  attr(:type, :atom, required: true)

  def message(%{type: type} = assigns) do
    assigns = assign(assigns, :class, Map.fetch!(@class, type))

    ~H"""
    <%= if @message do %>
      <div class={@class}>
        <%= for message <- List.wrap(@message) do %>
          <span class=""><%= message %></span>
        <% end %>
      </div>
    <% end %>
    """
  end

  def logo(assigns) do
    ~H"""
    <h1 class="text-4xl font-bold uppercase tracking-wide">Nectarine</h1>
    """
  end
end
