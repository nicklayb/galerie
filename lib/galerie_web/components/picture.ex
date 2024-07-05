defmodule GalerieWeb.Components.Picture do
  use Phoenix.Component

  use GalerieWeb.Components.Routes

  def thumbnail(assigns) do
    ~H"""
    <div class="">
      <img class="h-full max-h-72 w-full rounded-md shadow-md border-4 object-cover border-true-gray-300" src={~p(/pictures/#{@picture.fullpath})} />
    </div>
    """
  end
end
