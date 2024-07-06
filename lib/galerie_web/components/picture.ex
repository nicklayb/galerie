defmodule GalerieWeb.Components.Picture do
  use Phoenix.Component

  use GalerieWeb.Components.Routes

  attr(:picture, Galerie.Picture, required: true)
  attr(:checked, :boolean, default: false)

  def thumbnail(assigns) do
    ~H"""
    <div class={"relative group " <> if @checked, do: "scale-90", else: ""} phx-click={if @checked, do: "deselect-picture", else: "select-picture"} phx-value-picture_id={@picture.id}>
      <img class={"h-full max-h-72 w-full z-10 rounded-md shadow-md border-4 group object-cover border-true-gray-300 " <> if @checked, do: "border-pink-500", else: ""} src={~p(/pictures/#{@picture.fullpath})} />
      <div class="p-4 absolute z-20 top-0 w-full h-full bg-gray-500/40 hidden group-hover:block transition">
        <div class="">
        </div>
      </div>
    </div>
    """
  end
end
