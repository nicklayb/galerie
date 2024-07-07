defmodule GalerieWeb.Components.Picture do
  use Phoenix.Component

  use GalerieWeb.Components.Routes

  alias Galerie.Picture
  alias GalerieWeb.Components.Icon

  attr(:picture, Picture, required: true)
  attr(:checked, :boolean, default: false)

  def thumbnail(assigns) do
    ~H"""
    <div class={"relative transition select-none group " <> if @checked, do: "scale-90", else: ""} phx-click="picture-click" phx-value-picture_id={@picture.id} phx-value-index={@picture.index}>
      <img class={"h-full max-h-72 w-full z-10 rounded-md shadow-md border-4 group object-cover border-true-gray-300 " <> if @checked, do: "border-pink-500", else: ""} src={~p(/pictures/#{@picture.fullpath}?#{[type: "thumb"]})} />
      <%= if not @checked do %>
        <div class="p-4 absolute z-20 top-0 w-full h-full bg-gray-500/40 opacity-0 group-hover:opacity-100 transition">
          <div class="text-white border-2 border-pink-400 w-7 h-7 flex items-center justify-center rounded-full" phx-click="select-picture" phx-value-picture_id={@picture.id} phx-value-index={@picture.index}>
          </div>
        </div>
      <% end %>
      <%= if @checked do %>
        <div class="p-4 absolute z-20 top-0 w-full h-full transition">
          <div class="text-white border-2 border-pink-600 bg-pink-600 w-7 h-7 flex items-center justify-center rounded-full" phx-click="deselect-picture" phx-value-picture_id={@picture.id} phx-value-index={@picture.index}>
            <Icon.check width="15" height="15" />
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:picture, Picture, required: true)
  attr(:index, :integer, required: true)
  attr(:on_keyup, :string, default: "viewer:keyup")
  attr(:on_close, :string, default: "viewer:close")

  def viewer(assigns) do
    ~H"""
    <%= with {:ok, jpeg} <- Picture.jpeg_path(@picture) do %>
      <div class="z-50 fixed top-0 left-0 w-screen h-screen" phx-window-keyup={@on_keyup}>
        <img src={~p(/pictures/#{jpeg}?#{[type: @picture.type]})} />
      </div>
    <% end %>
    """
  end
end
