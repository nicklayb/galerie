defmodule GalerieWeb.Core.Notifications do
  use Phoenix.LiveView

  require Galerie.PubSub
  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Core.Notifications.Message

  @id "notifications"
  def id, do: @id

  def mount(
        _params,
        %{"current_user" => current_user, "live_session_id" => live_session_id},
        socket
      ) do
    socket =
      socket
      |> assign(:messages, [])
      |> assign(:current_user, current_user)
      |> assign(:live_session_id, live_session_id)

    if connected?(socket) do
      Galerie.PubSub.subscribe(:notifications)
      Galerie.PubSub.subscribe({:sessions, live_session_id})
      Galerie.PubSub.subscribe(current_user)
    end

    {:ok, socket}
  end

  def handle_info(
        %Galerie.PubSub.Message{message: :notify, params: {type, message, options}},
        socket
      ) do
    socket = update(socket, :messages, &add_message(&1, Message.new(type, message, options)))

    {:noreply, socket}
  end

  def handle_info(
        %Galerie.PubSub.Message{message: :update_notification, params: {key, function}},
        socket
      ) do
    socket = update(socket, :messages, &update_message(&1, key, function))

    {:noreply, socket}
  end

  def handle_info(%Galerie.PubSub.Message{}, socket) do
    {:noreply, socket}
  end

  def handle_info({:notifications, {:clear, id}}, socket) do
    socket = update(socket, :messages, &clear_message(&1, id))
    {:noreply, socket}
  end

  def handle_event("clear", %{"id" => id}, socket) do
    socket = update(socket, :messages, &clear_message(&1, id))
    {:noreply, socket}
  end

  defp update_message(messages, nil, function) do
    add_message(messages, function)
  end

  defp update_message(messages, key, function) do
    {found, messages} =
      Enum.reduce(messages, {false, []}, fn current_message, {found, acc} ->
        if current_message.key == key do
          {true, add_message(acc, function.(current_message.params))}
        else
          {found, add_message(acc, current_message)}
        end
      end)

    if found do
      messages
    else
      add_message(messages, function)
    end
  end

  defp add_message(messages, function) when is_function(function, 1) do
    add_message(messages, function.(%{}))
  end

  defp add_message(messages, {type, message, options}) do
    add_message(messages, Message.new(type, message, options))
  end

  defp add_message(messages, %Message{} = message) do
    [message | messages]
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
    <div class="fixed bottom-0 right-0 m-2 z-80">
      <%= for message <- @messages do %>
        <.message message={message} />
      <% end %>
    </div>
    """
  end

  @base_class "flex items-center px-3 py-4 rounded-lg shadow-lg min-w-80 mb-1 last:mb-0 transition-all slide-left"
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
      <div class="flex flex-1">
        <%= @message.message %>
      </div>
      <div class="cursor-pointer" phx-click="clear" phx-value-id={@message.id}>
        <Icon.cross width="14" height="14"/>
      </div>
    </div>
    """
  end

  def notify(
        %Phoenix.LiveView.Socket{assigns: %{current_user: current_user}} = socket,
        type,
        message,
        options \\ []
      ) do
    Galerie.PubSub.broadcast(current_user, {:notify, {type, message, options}})
    socket
  end
end
