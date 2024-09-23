defmodule GalerieWeb.Components.Dropzone do
  use Phoenix.Component

  attr(:id, :any, required: true)
  attr(:upload, :any, required: true)
  attr(:class, :string, default: "")
  slot(:inner_block, required: true)

  def render(assigns) do
    ~H"""
    <%= if Galerie.Accounts.User.can?(@current_user, :upload_pictures) do %>
      <div phx-drop-target={@upload.ref} class={@class} phx-hook="Dropzone" id={@id}>
        <form id="test" phx-change="validate_file">
        <.live_file_input upload={@upload} class="hidden" />
        </form>
        <%= render_slot(@inner_block) %>
      </div>
    <% else %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end
end
