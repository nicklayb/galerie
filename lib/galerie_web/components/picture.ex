defmodule GalerieWeb.Components.Picture do
  use Phoenix.Component

  use GalerieWeb.Components.Routes

  def thumbnail(assigns) do
    ~H"""
    <div class="">
      <img class="h-auto max-w-full rounded-md border-2 border-white" src={~p(/pictures/#{@picture.fullpath})} />
    </div>
    """
  end
end
