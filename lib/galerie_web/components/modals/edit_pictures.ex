defmodule GalerieWeb.Components.Modals.EditPictures do
  use Phoenix.LiveComponent

  import GalerieWeb.Gettext

  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Modal
  alias GalerieWeb.Components.Modals.EditPictures.Form, as: EditPicturesForm
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
        "edit_pictures:change",
        %{"edit_pictures" => %{"album_ids" => album_ids, "metadatas" => metadatas}},
        socket
      ) do
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
            </div>
          </:body>
        </Modal.modal>
      </.form>
    </div>
    """
  end

  defp edit_metadata(assigns) do
    assigns =
      assign(assigns, :metadata_inputs, GalerieWeb.Form.form_keys(EditPicturesForm.Metadatas))

    ~H"""
    <div class="">
      <%= for metadata_input <- @metadata_inputs do %>
        <.inputs_for :let={metadatas} field={@form[:metadatas]}>
          <Form.text_input field={metadatas[metadata_input]} label={PictureGettext.translate_metadata(metadata_input)} />
        </.inputs_for>
      <% end %>
    </div>
    """
  end

  defp add_to_album(assigns) do
    ~H"""
    <ul>
      <%= for {_, album} <- @albums do %>
        <li class="border border-true-gray-300 border-b-0 py-1 pl-1 pr-2 last:border-b first:rounded-t-md last:rounded-b-md">
          <Form.checkbox label={album.name} field={@form[:album_ids]} checked={album.id in @form[:album_ids].value} multiple={true} value={album.id} element_class="flex flex-row justify-between items-center" />
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
    <div class="">
      <div class="" phx-click="edit_pictures:expand" phx-value-key={@key} phx-target={@myself}>
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
