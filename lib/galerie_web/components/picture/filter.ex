defmodule GalerieWeb.Components.Picture.Filter do
  use Phoenix.LiveComponent

  require Galerie.PubSub

  alias GalerieWeb.Components.Multiselect
  alias GalerieWeb.Gettext.Picture, as: PictureGettext

  @metadata_filters [
    lens_model: :lens_models,
    focal_length: :focal_lengths,
    camera_model: :camera_models,
    f_number: :f_numbers,
    exposure_time: :exposure_times
  ]
  @other_filters [rating: :ratings]
  @multiselect_filters @other_filters ++ @metadata_filters
  @metadata_filter_keys Keyword.keys(@metadata_filters)
  def mount(socket) do
    socket =
      socket
      |> assign(:ratings, Multiselect.new(:rating))
      |> assign_metadata_filters()

    {:ok, socket}
  end

  defp assign_metadata_filters(socket, keys \\ @metadata_filter_keys) do
    Enum.reduce(keys, socket, fn metadata, acc ->
      case Keyword.get(@metadata_filters, metadata) do
        nil ->
          acc

        assign_name ->
          assign(acc, assign_name, init_or_update_filter(acc, assign_name, {:metadata, metadata}))
      end
    end)
  end

  def init_or_update_filter(socket, assign_name, type) do
    case Map.get(socket.assigns, assign_name) do
      %Multiselect.State{} = multiselect ->
        Multiselect.State.update(multiselect)

      _ ->
        Multiselect.new(type)
    end
  end

  def update(%{updated_metadata: updated_metadata}, socket) do
    socket = assign_metadata_filters(socket, updated_metadata)
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok, socket}
  end

  def handle_event("filter:" <> filter_event, params, socket) do
    [assign, event] = String.split(filter_event, ":", parts: 2)

    socket =
      update_filter(
        socket,
        String.to_existing_atom(assign),
        &Multiselect.handle_event(event, params, &1)
      )

    {:noreply, socket}
  end

  defp update_filter(socket, assign, function) do
    socket
    |> update(assign, function)
    |> tap(&send(self(), {:filter_updated, filter_values(&1.assigns)}))
  end

  defp filter_values(assigns) do
    Enum.map(@multiselect_filters, fn {key, assign} ->
      assign_value = Map.fetch!(assigns, assign)
      {key, filter_value(assign_value)}
    end)
  end

  defp filter_value(%Multiselect.State{} = multiselect) do
    Multiselect.selected_items(multiselect)
  end

  defp filter_value(%SelectableList{} = selectable_list) do
    SelectableList.selected_items(selectable_list, fn {_, item} -> item.id end)
  end

  defp filter_label(metadata), do: PictureGettext.translate_filter(metadata)

  def render(assigns) do
    filters =
      Enum.map(@multiselect_filters, fn {_metadata, assign_name} ->
        {assign_name, assigns[assign_name], filter_label(assign_name)}
      end)

    assigns = assign(assigns, :multiselect_filters, filters)

    ~H"""
    <div>
      <%= for {assign, multiselect_state, label} <- @multiselect_filters do %>
        <div class="px-2 mt-2">
          <Multiselect.render state={multiselect_state} prefix={"filter:#{assign}"} label={label} target={@myself}/>
        </div>
      <% end %>
    </div>
    """
  end
end
