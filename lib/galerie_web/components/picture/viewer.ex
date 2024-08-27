defmodule GalerieWeb.Components.Picture.Viewer do
  use Phoenix.LiveComponent
  use GalerieWeb.Components.Routes

  require Logger

  import GalerieWeb.Gettext

  alias Galerie.Albums
  alias Galerie.Pictures
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Group
  alias Galerie.Pictures.Picture.Metadata
  alias Galerie.Pictures.PictureItem
  alias Galerie.Repo
  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Components.Stars
  alias GalerieWeb.Components.Ui
  alias GalerieWeb.Html

  @defaults [
    on_keyup: "viewer:keyup",
    on_close: "viewer:close",
    selected_pictures: [],
    editing_metadata: nil,
    rating_range: Group.rating_range()
  ]

  def mount(socket) do
    socket = assign(socket, @defaults)
    {:ok, socket}
  end

  def update(%{results: results} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_pictures(results)
      |> assign_metadata_changeset()

    {:ok, socket}
  end

  @updatable_messages ~w(
    processed
    removed_from_album
    rating_updated
    metadata_updated
  )a
  def update(%{message: %Galerie.PubSub.Message{message: message}}, socket)
      when message in @updatable_messages do
    socket = assign_pictures(socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, socket}
  end

  def interesting_messages, do: @updatable_messages

  def handle_event(
        "viewer:remove-from-album",
        %{"album_id" => album_id, "group_id" => group_id},
        socket
      ) do
    Albums.remove_from_album(%{album_id: album_id, group_id: group_id})
    {:noreply, socket}
  end

  def handle_event("viewer:edit_metadata", %{"metadata" => string_metadata}, socket) do
    metadata = String.to_existing_atom(string_metadata)

    socket =
      socket
      |> assign(:editing_metadata, metadata)
      |> assign_metadata_changeset()

    {:noreply, socket}
  end

  def handle_event(
        "viewer:metadata:change",
        %{"_target" => ["metadata", _], "metadata" => metadata},
        socket
      ) do
    socket = assign_metadata_changeset(socket, metadata)
    {:noreply, socket}
  end

  def handle_event("viewer:metadata:save", %{"metadata" => metadata}, socket) do
    socket =
      case Pictures.update_metadata_manually(socket.assigns.picture.group_id, metadata) do
        {:ok, _} ->
          assign(socket, :editing_metadata, nil)

        {:error, error} ->
          Logger.error("[#{inspect(__MODULE__)}] [viewer:metadata:save] #{inspect(error)}")
          socket
      end

    {:noreply, socket}
  end

  def handle_event("viewer:metadata:cancel", _, socket) do
    socket = assign(socket, :editing_metadata, nil)

    {:noreply, socket}
  end

  def handle_event(
        "viewer:rate",
        %{"rating" => rating},
        %{assigns: %{picture_item: picture_item}} = socket
      ) do
    socket =
      case Pictures.update_rating(picture_item.group_id, String.to_integer(rating)) do
        {:ok, %Group{rating: rating}} ->
          update(socket, :picture_item, &%PictureItem{&1 | rating: rating})

        _ ->
          socket
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="z-50 fixed flex flex-row top-0 left-0 w-screen h-screen bg-gray-800/90 fade-in transition-all" data-on-window-keyup={@on_keyup} phx-hook="Keyup" id="viewerWrapper">
      <div class="flex-1 flex flex-row text-white text-lg">
        <.side_arrow disabled={not @has_previous} icon={:left_chevron} on_keyup={@on_keyup} key="ArrowLeft"/>
        <div class="py-2"><img class={Html.class("h-full m-auto", rotation(@picture))} src={~p(/pictures/#{@picture.id})} /></div>
        <.side_arrow disabled={not @has_next} icon={:right_chevron} on_keyup={@on_keyup} key="ArrowRight"/>
      </div>
      <.info_panel
        checked={@checked}
        picture={@picture}
        picture_item={@picture_item}
        rating_range={@rating_range}
        index={@results.highlighted_index}
        on_close={@on_close}
        pictures={@pictures}
        myself={@myself}
        editing_metadata={@editing_metadata}
        metadata_changeset={@metadata_changeset}
      />
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
    ~H"""
    <div class="flex flex-col flex-initial w-96 bg-white transition-all slide-left">
      <div class="flex flex-row justify-between items-center px-2 py-2">
        <span class="text-md flex items-center">
          <Ui.select_marker checked={@checked} class="mr-2" on_select="select-picture" on_deselect="deselect-picture" phx-value-picture_id={@picture.id} phx-value-index={@index} />
          <%= @picture.name %>
        </span>
        <span class="top-0 right-0 cursor-pointer pr-1" phx-click={@on_close}>
          <Icon.cross width="14" height="14" />
        </span>
      </div>
      <div class="p-3">
        <Stars.render value={@picture_item.rating} range={@rating_range} phx-click="viewer:rate" phx-target={@myself} />
      </div>
      <div>
        <%= with %Metadata{} = metadata <- @picture.metadata do %>
          <.info_section title={gettext("Informations")} myself={@myself} editing_metadata={@editing_metadata} metadata_changeset={@metadata_changeset} manually_updated_fields={@picture.metadata.manually_updated_fields}>
            <:info_item title={gettext("Taken on")}>
              <%= metadata.datetime_original %>
            </:info_item>
            <:info_item title={gettext("Camera")} editable_name={:camera_model}>
              <%= metadata.camera_make %> <%= metadata.camera_model %>
            </:info_item>
            <:info_item title={gettext("F stop")} visible={metadata.f_number > 0} editable_name={:f_number}>
              <%= gettext("f/%{focal}", focal: metadata.f_number) %>
            </:info_item>
            <:info_item title={gettext("Focal length")} editable_name={:focal_length} visible={not is_nil(metadata.focal_length) and metadata.focal_length > 0.0}>
              <%= metadata.focal_length %>
            </:info_item>
            <:info_item title={gettext("Dimensions")}>
              <%= metadata.width %>
              <span class="mx-0.5">x</span>
              <%= metadata.height %>
            </:info_item>
            <:info_item title={gettext("Exposure")} editable_name={:exposure_time}>
              <%= with %Fraction{} = fraction <- metadata.exposure_time do %>
                <Icon.aperture width="18" height="18" class="mr-1" />
                <%= Fraction.to_string(fraction) %>
              <% end %>
            </:info_item>
            <:info_item title={gettext("GPS")} visible={metadata.longitude}>
              <.google_map_link longitude={metadata.longitude} latitude={metadata.latitude} />
            </:info_item>
            <:info_item title={gettext("Lens")} visible={metadata.lens_model} editable_name={:lens_model}>
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
        <.info_section title={gettext("Albums (%{count})", count: length(@picture.albums))}>
          <%= for album <- @picture.albums do %>
            <.info_section_item title={album.name}>
              <Ui.button phx-click="viewer:remove-from-album" phx-value-group_id={@picture.group_id} phx-value-album_id={album.id} phx-target={@myself}>
                <Icon.cross height="14" width="14"/>
              </Ui.button>
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
  attr(:myself, :any)
  attr(:editing_metadata, :atom, default: nil)
  attr(:metadata_changeset, :map, default: nil)
  attr(:manually_updated_fields, MapSet, default: MapSet.new())
  slot(:inner_block, required: false)

  slot(:info_item, required: false) do
    attr(:title, :string, required: true)
    attr(:editable_name, :atom)
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
        <%= if Map.get(item, :visible, true) != false or not is_nil(Map.get(item, :editable_name)) do %>
          <.info_section_item title={item.title} editable_name={Map.get(item, :editable_name)} editing_metadata={@editing_metadata} metadata_changeset={@metadata_changeset} myself={@myself} manually_updated_fields={@manually_updated_fields}>
            <%= render_slot(item) %>
          </.info_section_item>
        <% end %>
      <% end %>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:myself, :any)
  attr(:editable_name, :atom, default: nil)
  attr(:editing_metadata, :atom, default: nil)
  attr(:metadata_changeset, :map)
  attr(:manually_updated_fields, MapSet, default: MapSet.new([]))
  slot(:inner_block, required: false)

  defp info_section_item(assigns) do
    editable? = not is_nil(assigns.editable_name)

    assigns =
      assigns
      |> assign(
        :editing?,
        editable? and assigns.editable_name == assigns.editing_metadata
      )
      |> assign(:editable?, editable?)
      |> assign(
        :manually_edited?,
        MapSet.member?(assigns.manually_updated_fields, assigns.editable_name)
      )

    ~H"""
    <div class="flex flex-row justify-between text-sm py-0.5 border-b border-gray-100 group">
      <div class="flex pl-2">
        <%= @title %>
        <%= if @editable? and not @editing? do %>
          <span phx-click="viewer:edit_metadata" phx-value-metadata={@editable_name} phx-target={@myself} class={Html.class("group-hover:block cursor-pointer hover:text-pink-600", [{@manually_edited?, "block text-gray-300", "hidden"}])}>
            <Icon.pencil width="18" height="18"/>
          </span>
        <% end %>
      </div>
      <div class="flex pr-2">
        <%= if @editing? do %>
          <.form for={@metadata_changeset} as={:edit_metadata} phx-change="viewer:metadata:change" phx-submit="viewer:metadata:save" phx-target={@myself}>
            <Form.text_input field={@metadata_changeset[@editable_name]} class="px-1 py-0" phx-hook="EditingMetadata" element_class="mb-0" id="editingMetadata" data-myself={@myself}/>
            <button type="submit" class="hidden"></button>
          </.form>
        <% else %>
          <%= render_slot(@inner_block) %>
        <% end %>
      </div>
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

  defp assign_pictures(%{assigns: %{picture_item: picture_item}} = socket) do
    assign_pictures(socket, picture_item)
  end

  defp assign_pictures(socket, %SelectableList{} = pictures) do
    picture_item = SelectableList.highlighted_item(pictures)

    socket
    |> assign(:has_previous, not SelectableList.first_highlighted?(pictures))
    |> assign(
      :has_next,
      socket.assigns.has_next_page or not SelectableList.last_highlighted?(pictures)
    )
    |> assign(:checked, SelectableList.index_selected?(pictures, pictures.highlighted_index))
    |> assign_pictures(picture_item)
  end

  defp assign_pictures(socket, %PictureItem{} = picture_item) do
    picture_item = Pictures.reload_picture_item(picture_item)
    pictures = Galerie.Pictures.get_grouped_pictures(picture_item)

    picture = Enum.find(pictures, &(&1.id == picture_item.main_picture_id))

    socket
    |> assign(:picture_item, picture_item)
    |> assign(:picture, picture)
    |> assign(:pictures, pictures)
    |> update(:picture, &Repo.preload(&1, [:exif, :metadata, :albums]))
  end

  defp assign_metadata_changeset(socket, params \\ %{}) do
    changeset =
      socket.assigns.picture.metadata
      |> Metadata.changeset(params)
      |> to_form()

    assign(
      socket,
      :metadata_changeset,
      changeset
    )
  end
end
