defmodule NectarineWeb.Components.Modal do
  use Phoenix.LiveComponent
  alias NectarineWeb.Components.Ui
  alias Phoenix.LiveView.JS

  def show_modal(module, attrs) do
    send_update(__MODULE__, id: id(), show: Enum.into(attrs, %{module: module}))
  end

  def hide_modal do
    send_update(__MODULE__, id: id(), show: nil)
  end

  def update(%{id: id} = assigns, socket) do
    show =
      case Map.get(assigns, :show) do
        %{module: _module, title: _} = show ->
          Map.put_new(show, :on_cancel, Map.Extra.get_with_default(show, :on_cancel, %JS{}))

        nil ->
          nil
      end

    {:ok, assign(socket, id: id, show: show)}
  end

  def render(assigns) do
    ~H"""
    <div class={unless @show, do: "hidden"}>
      <%= if @show do %>
        <Ui.modal
          show
          id={@id}
          on_cancel={@show.on_cancel}
        >
          <:header><%= @show.title %></:header>
          <:body><.live_component module={@show.module} {@show} /></:body>
        </Ui.modal>
      <% end %>
    </div>
    """
  end

  def id, do: "modal"
end
