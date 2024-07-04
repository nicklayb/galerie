defmodule NectarineWeb.Authentication.View do
  use Phoenix.Component
  use NectarineWeb.Components.Routes
  import NectarineWeb.Gettext
  alias NectarineWeb.Components.Form
  alias NectarineWeb.Components.Layouts
  alias Phoenix.HTML.Form, as: PhoenixForm

  embed_templates("templates/*")

  slot(:inner_block, required: true)

  def container(assigns) do
    ~H"""
    <div class="bg-gray-800 rounded-lg p-4">
      <div class="text-center my-4">
        <Layouts.logo />
      </div>

      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
