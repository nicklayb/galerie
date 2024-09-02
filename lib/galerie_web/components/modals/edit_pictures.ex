defmodule GalerieWeb.Components.Modals.EditPictures do
  use GalerieWeb, :live_component

  alias Galerie.Form.Pictures.EditPicturesForm

  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Components.Modal
  alias GalerieWeb.Core.Notifications
  alias GalerieWeb.Gettext.Picture, as: PictureGettext
  alias GalerieWeb.Html

  @expandable_blocks ~w(metadata albums)a
  @expandable_block_strings Enum.map(@expandable_blocks, &to_string/1)

  @default_assigns [
    expanded: MapSet.new()
  ]
  def mount(socket) do
    socket = assign(socket, @default_assigns)
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_selectable_list()

    {:ok, socket}
  end

  def handle_event("edit_pictures:expand", %{"key" => key}, socket)
      when key in @expandable_block_strings do
    socket = update(socket, :expanded, &MapSet.Extra.toggle(&1, String.to_existing_atom(key)))

    {:noreply, socket}
  end

  def handle_event(
        "edit_pictures:save",
        %{"edit_pictures" => params},
        socket
      ) do
    album_ids = Map.get(params, "album_ids", [])
    metadatas = Map.get(params, "metadatas", %{})

    params = %{
      group_ids: socket.assigns.group_ids,
      album_ids: album_ids,
      metadatas: metadatas
    }

    socket =
      with {:ok, form} <- EditPicturesForm.submit(params),
           {:ok, _result} <- UseCase.execute(socket, Galerie.Pictures.UseCase.EditPictures, form) do
        send(self(), :close_modal)
        Notifications.notify(socket, :info, gettext("Pictures edited successfully"))
      else
        _error ->
          Notifications.notify(
            socket,
            :error,
            gettext("Error occured while updating the pictures")
          )
      end

    {:noreply, socket}
  end

  def handle_event(
        "edit_pictures:change",
        %{"edit_pictures" => params},
        socket
      ) do
    album_ids = Map.get(params, "album_ids", [])
    metadatas = Map.get(params, "metadatas", %{})

    socket =
      assign(
        socket,
        :form,
        EditPicturesForm.new(%{
          group_ids: socket.assigns.group_ids,
          album_ids: album_ids,
          metadatas: metadatas
        })
      )

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="">
      <.form for={@form} class="relative" phx-change="edit_pictures:change" phx-submit="edit_pictures:save" phx-target={@myself}>
        <Modal.modal>
          <:header>
            <%= gettext("Edit %{count} pictures", count: @count) %>
          </:header>
          <:body>
            <div class="">
              <.block_wrapper expanded={@expanded} key={:albums} myself={@myself}>
                <.add_to_album myself={@myself} albums={@albums} form={@form} />
              </.block_wrapper>
              <.block_wrapper expanded={@expanded} key={:metadata} myself={@myself}>
                <.edit_metadata expanded={@expanded} myself={@myself} form={@form} />
              </.block_wrapper>
              <div class="px-1 py-2 border-b last:border-b-0 border-true-gray-200 text-right">
                <Form.button type={:submit}><%= gettext("Save") %></Form.button>
              </div>
            </div>
          </:body>
        </Modal.modal>
      </.form>
    </div>
    """
  end

  defp edit_metadata(assigns) do
    assigns =
      assign(assigns, :metadata_inputs, EditPicturesForm.Metadatas.text_inputs())

    ~H"""
    <div class="">
      <%= for metadata_input <- @metadata_inputs do %>
        <.inputs_for :let={metadatas} field={@form[:metadatas]}>
          <div>
            <.metadata_input metadata_input={metadata_input} form={metadatas} />
          </div>
        </.inputs_for>
      <% end %>
    </div>
    """
  end

  defp metadata_input(assigns) do
    assigns =
      assigns
      |> assign(:field, assigns.form[assigns.metadata_input])
      |> assign(:checked_key, String.to_existing_atom("#{assigns.metadata_input}_edited"))
      |> assign(:label, PictureGettext.translate_metadata(assigns.metadata_input))
      |> then(&assign(&1, :checked_field, &1.form[&1.checked_key]))
      |> then(&assign(&1, :checked?, &1.checked_field.value == true))

    ~H"""
    <Form.text_input field={@field} disabled={not @checked?}>
      <:label>
        <div class="flex items-center">
          <Form.checkbox field={@checked_field} checked={@checked?} value="true" element_class="flex mb-0 mr-1"/>
          <div><%= @label %></div>
        </div>
      </:label>
    </Form.text_input>
    """
  end

  defp add_to_album(assigns) do
    ~H"""
    <ul>
      <%= for {_, album} <- @albums do %>
        <li class="border border-true-gray-300 border-b-0 py-1 pl-1 pr-2 last:border-b first:rounded-t-md last:rounded-b-md">
          <Form.checkbox field={@form[:album_ids]} checked={album.id in @form[:album_ids].value} multiple={true} value={album.id} element_class="flex flex-row justify-between items-center">
            <:label><%= album.name %></:label>
          </Form.checkbox>
        </li>
      <% end %>
    </ul>
    """
  end

  defp block_wrapper(assigns) do
    assigns =
      assigns
      |> assign(:label, block_label(assigns.key))
      |> assign(:expanded?, MapSet.member?(assigns.expanded, assigns.key))

    ~H"""
    <div class="px-1 py-2 border-b last:border-b-0 border-true-gray-200">
      <div class="text-lg flex items-center cursor-pointer" phx-click="edit_pictures:expand" phx-value-key={@key} phx-target={@myself}>
        <%= if @expanded? do %>
          <Icon.down_chevron width="20" height="20" />
        <% else %>
          <Icon.right_chevron width="20" height="20" />
        <% end %>
        <%= @label %>
      </div>
      <div class={Html.class("", {@expanded?, "block", "hidden"})}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp assign_selectable_list(%{assigns: %{selectable_list: %SelectableList{}}} = socket) do
    socket
    |> update(:selectable_list, fn selectable_list ->
      SelectableList.selected_items(selectable_list, fn {_, item} -> item end)
    end)
    |> then(&assign(&1, :count, length(&1.assigns.selectable_list)))
    |> then(fn socket ->
      group_ids = Enum.map(socket.assigns.selectable_list, & &1.group_id)

      socket
      |> assign(:group_ids, group_ids)
      |> assign(:form, EditPicturesForm.new(%{group_ids: group_ids}))
    end)
  end

  defp block_label(:albums), do: gettext("Add to albums")
  defp block_label(:metadata), do: gettext("Edit metadata")
end
