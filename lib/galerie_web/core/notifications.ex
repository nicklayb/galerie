defmodule GalerieWeb.Core.Notifications do
  alias GalerieWeb.Core.Notifications.Message
  use Phoenix.LiveView

  require Galerie.PubSub

  @id "notifications"
  def id, do: @id

  def mount(
        _params,
        %{"current_user" => current_user, "live_session_id" => live_session_id},
        socket
      ) do
    socket =
      socket
      |> assign(:messages, [Message.new(:info, "Ah yes!"), Message.new(:error, "Ah non.")])
      |> assign(:current_user, current_user)
      |> assign(:live_session_id, live_session_id)

    if connected?(socket) do
      Galerie.PubSub.subscribe({:sessions, live_session_id})
      Galerie.PubSub.subscribe(current_user)
    end

    {:ok, socket}
  end

  def handle_info({:notifications, {:clear, id}}, socket) do
    socket = update(socket, :messages, &clear_message(&1, id))
    {:noreply, socket}
  end

  defp clear_message(messages, id) do
    Enum.reject(messages, fn message ->
      with true <- message.id == id do
        Message.clear(message)
        true
      end
    end)
  end

  def render(assigns) do
    assigns = update(assigns, :messages, &Enum.reverse/1)

    ~H"""
    <div class="fixed bottom-0 right-0 m-2">
      <%= for message <- @messages do %>
        <.message message={message} />
      <% end %>
    </div>
    """
  end

  @base_class "px-3 py-4 rounded-lg shadow-lg min-w-80 mb-1 last:mb-0"
  @types_classes %{
    info: "bg-pink-400 text-white",
    error: "bg-red-500 text-white"
  }
  @classes Enum.reduce(
             @types_classes,
             %{},
             &Map.put(&2, elem(&1, 0), "#{@base_class} #{elem(&1, 1)}")
           )

  defp message(assigns) do
    assigns = assign(assigns, :class, Map.fetch!(@classes, assigns.message.type))

    ~H"""
    <div class={@class} data-notification-id={@message.id}>
      <%= @message.message %>
    </div>
    """
  end
end
