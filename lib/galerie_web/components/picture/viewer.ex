defmodule GalerieWeb.Components.Picture.Viewer do
  use Phoenix.LiveComponent

  use GalerieWeb.Components.Routes

  import GalerieWeb.Gettext

  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Metadata
  alias Galerie.Pictures.PictureItem
  alias Galerie.Repo
  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Components.Ui
  alias GalerieWeb.Html

  @defaults [
    on_keyup: "viewer:keyup",
    on_close: "viewer:close",
    selected_pictures: []
  ]

  def mount(socket) do
    socket = assign(socket, @defaults)
    {:ok, socket}
  end

  def update(%{picture: %PictureItem{} = picture_item} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_pictures(picture_item)

    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="z-50 fixed flex flex-row top-0 left-0 w-screen h-screen bg-gray-800/90" phx-window-keyup={@on_keyup}>
      <div class="flex-1 flex flex-row text-white text-lg">
        <.side_arrow disabled={not @has_previous} icon={:left_chevron} on_keyup={@on_keyup} key="ArrowLeft"/>
        <div class="py-2"><img class={Html.class("h-full m-auto", rotation(@picture))} src={~p(/pictures/#{@picture.id})} /></div>
        <.side_arrow disabled={not @has_next} icon={:right_chevron} on_keyup={@on_keyup} key="ArrowRight"/>
      </div>
      <.info_panel checked={MapSet.member?(@selected_pictures, @picture.id)} picture={@picture} index={@index} on_close={@on_close} pictures={@pictures} />
    </div>
    """
  end

  attr(:key, :string, required: true)
  attr(:on_keyup, :string, required: true)
  attr(:disabled, :boolean, required: true)
  attr(:icon, :atom, required: true)

  defp side_arrow(assigns) do
    ~H"""
    <div class={Html.class("content-center transition text-gray-400 bg-gray-900/0", {not @disabled, "text-white cursor-pointer hover:bg-gray-900/40"})} phx-click={@on_keyup} phx-value-key={@key}>
      <Icon.icon icon={@icon} width="40" height="40" />
    </div>
    """
  end

  defp info_panel(assigns) do
    assigns = update(assigns, :picture, &Repo.preload(&1, [:exif, :metadata]))

    ~H"""
    <div class="flex flex-col flex-initial w-96 bg-white">
      <div class="flex flex-row justify-between items-center px-2 py-2">
        <span class="text-md flex items-center">
          <Ui.select_marker checked={@checked} class="mr-2" on_select="select-picture" on_deselect="deselect-picture" phx-value-picture_id={@picture.id} phx-value-index={@index} />
          <%= @picture.name %>
        </span>
        <span class="top-0 right-0 cursor-pointer pr-1" phx-click={@on_close}>
          <Icon.cross width="14" height="14" />
        </span>
      </div>
      <div>
        <%= with %Metadata{} = metadata <- @picture.metadata do %>
          <.info_section title={gettext("Informations")}>
            <:info_item title={gettext("Taken on")}>
              <%= metadata.datetime_original %>
            </:info_item>
            <:info_item title={gettext("Camera")}>
              <%= metadata.camera_make %> <%= metadata.camera_model %>
            </:info_item>
            <:info_item title={gettext("F stop")} visible={metadata.f_number > 0}>
              <%= gettext("f/%{focal}", focal: metadata.f_number) %>
            </:info_item>
            <:info_item title={gettext("Dimensions")}>
              <%= metadata.width %>
              <span class="mx-0.5">x</span>
              <%= metadata.height %>
            </:info_item>
            <:info_item title={gettext("Exposure")}>
              <Icon.aperture width="18" height="18" class="mr-1" />
              <%= 1 / metadata.exposure_time %>
            </:info_item>
            <:info_item title={gettext("GPS")} visible={metadata.longitude}>
              <.google_map_link longitude={metadata.longitude} latitude={metadata.latitude} />
            </:info_item>
            <:info_item title={gettext("Lens")} visible={metadata.lens_model}>
              <%= metadata.lens_model %>
            </:info_item>
          </.info_section>
        <% end %>
        <.info_section title={gettext("Versions (%{count})", count: length(@pictures))}>
          <%= for picture <- @pictures do %>
            <.info_section_item title={picture.original_name}>
              <Ui.link href={~p(/pictures/#{picture.id}?#{[type: "original"]})}>
                <Icon.download height="20" width="20"/>
              </Ui.link>
            </.info_section_item>
          <% end %>
        </.info_section>
      </div>
    </div>
    """
  end

  defp google_map_link(assigns) do
    ~H"""
    <Ui.link href={"https://maps.google.com/?q=#{@latitude},#{@longitude}"}>
      <%= gettext("Google Maps") %>
    </Ui.link>
    """
  end

  attr(:title, :string, required: true)
  slot(:inner_block, required: false)

  slot(:info_item, required: false) do
    attr(:title, :string, required: true)
    attr(:visible, :boolean)
  end

  defp info_section(assigns) do
    assigns = update(assigns, :info_item, fn items -> Enum.sort_by(items, & &1.title) end)

    ~H"""
    <div class="mt-2 first:mt-0">
      <div class="py-1 pl-2 bg-gray-200"><%= @title %></div>
      <%= if Enum.any?(@inner_block) do %>
        <%= render_slot(@inner_block) %>
      <% end %>
      <%= for item <- @info_item do %>
        <%= if Map.get(item, :visible, true) do %>
          <.info_section_item title={item.title}>
            <%= render_slot(item) %>
          </.info_section_item>
        <% end %>
      <% end %>
    </div>
    """
  end

  attr(:title, :string, required: true)
  slot(:inner_block, required: false)

  defp info_section_item(assigns) do
    ~H"""
    <div class="flex flex-row justify-between text-sm py-0.5 border-b border-gray-100">
      <div class="flex pl-2"><%= @title %></div>
      <div class="flex pr-2"><%= render_slot(@inner_block) %></div>
    </div>
    """
  end

  defp rotation(%Picture{} = picture) do
    picture
    |> Picture.rotation()
    |> rotation()
  end

  defp rotation(90), do: "rotate-270"
  defp rotation(180), do: "rotate-180"
  defp rotation(_), do: nil

  defp assign_pictures(socket, %PictureItem{} = picture_item) do
    pictures = Galerie.Pictures.get_grouped_pictures(picture_item)

    picture =
      pictures
      |> Enum.find(&(&1.id == picture_item.main_picture_id))
      |> Repo.preload([:exif])

    socket
    |> assign(:picture, picture)
    |> assign(:pictures, pictures)
  end
end
