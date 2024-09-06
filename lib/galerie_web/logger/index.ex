defmodule GalerieWeb.Logger.Index do
  use Phoenix.LiveView
  use GalerieWeb.Components.Routes

  alias GalerieWeb.Logger.Messages

  @levels ~w(
      emergency
      alert
      critical
      error
      warning
      notice
      info
      debug
  )a
  @initial_messages Enum.reduce(@levels, %{}, &Map.put(&2, &1, Messages.new()))

  def mount(params, _, socket) do
    GalerieWeb.Logger.Config.subscribe()

    active_tab = tab_from_params(params, socket)

    socket =
      socket
      |> assign(:messages, @initial_messages)
      |> assign(:levels, @levels)
      |> assign_active_tab(active_tab)

    {:ok, socket}
  end

  def handle_params(params, _, socket) do
    active_tab = tab_from_params(params, socket)

    socket = assign_active_tab(socket, active_tab)

    {:noreply, socket}
  end

  def handle_event("set-tab", %{"level" => level}, socket) do
    {:noreply, assign_active_tab(socket, level)}
  end

  def handle_event("expand", %{"uuid" => uuid}, socket) do
    socket = update_active_messages(socket, &Messages.toggle(&1, uuid))
    {:noreply, socket}
  end

  def handle_event("search", %{"search" => search}, socket) do
    socket = update_active_messages(socket, &Messages.update_search(&1, search))
    {:noreply, socket}
  end

  def handle_event("clear", _, socket) do
    socket = update_active_messages(socket, &Messages.clear_messages/1)
    {:noreply, socket}
  end

  def handle_event("expand-all", _, socket) do
    socket = update_active_messages(socket, &Messages.expand_all/1)

    {:noreply, socket}
  end

  def handle_event("collapse-all", _, socket) do
    socket = update_active_messages(socket, &Messages.collapse_all/1)
    {:noreply, socket}
  end

  def handle_info(
        {:message,
         %{
           level: level,
           timestamp: timestamp,
           message: message,
           metadata: metadata
         } = params},
        socket
      ) do
    socket =
      if message_from_loggger_view?(params) do
        socket
      else
        put_message(socket, timestamp, level, message, metadata)
      end

    {:noreply, socket}
  end

  defp message_from_loggger_view?(params) do
    params
    |> Map.get(:metadata, [])
    |> Keyword.get(:pid)
    |> then(&(&1 == self()))
  end

  defp tab_from_params(params, socket) do
    current_tab =
      socket.assigns
      |> Map.get_lazy(:active_tab, fn -> get_config(:default_tab, :error) end)
      |> to_string()

    params
    |> Map.get("tab", current_tab)
    |> String.to_existing_atom()
  end

  defp assign_active_tab(socket, tab) when is_binary(tab),
    do: assign_active_tab(socket, String.to_existing_atom(tab))

  defp assign_active_tab(%{assigns: %{active_tab: active_tab}} = socket, active_tab), do: socket

  defp assign_active_tab(socket, tab) do
    socket
    |> assign(:active_tab, tab)
    |> update_active_messages(&Messages.clear_unread/1)
  end

  defp format_date({{year, month, day}, {hour, minute, seconds, milliseconds}}) do
    date = Enum.join([year, month, day], "-")
    hour = Enum.join([hour, minute, seconds], ":")

    "#{date} #{hour}.#{milliseconds}"
  end

  defp put_message(socket, timestamp, level, message, metadata) do
    update_messages(socket, level, fn messages ->
      messages = Messages.put_message(messages, timestamp, message, metadata)

      if level != socket.assigns.active_tab do
        Messages.increment(messages)
      else
        messages
      end
    end)
  end

  defp update_messages(socket, level, function) do
    update(socket, :messages, fn messages ->
      Map.update!(messages, level, function)
    end)
  end

  defp update_active_messages(%{assigns: %{active_tab: active_tab}} = socket, function) do
    update_messages(socket, active_tab, function)
  end

  @classes %{
    atom: "text-cyan-600",
    boolean: "text-magenta-600",
    charlist: "text-yellow-600",
    nil: "text-magenta-600",
    number: "text-yellow-600",
    string: "text-green-600"
  }
  @colors Enum.map(@classes, fn {key, class} -> {key, ~s(<span class="#{class}">)} end)

  defp prettify_value(value) do
    value
    |> inspect(pretty: true, syntax_colors: @colors, limit: :infinity)
    |> String.replace("\e[0m", "</span>")
  end

  defp get_config(key, default) do
    :logger
    |> Application.get_env(GalerieWeb.Logger.Index, [])
    |> Keyword.get(key, default)
  end

  def render(%{messages: messages} = assigns) do
    messages =
      messages
      |> Map.fetch!(assigns.active_tab)
      |> Messages.visible_messages()

    assigns = assign(assigns, :active_messages, messages)

    ~H"""
    <div class="flex flex-col h-screen">
      <div class="flex-initial p-4 min-w-48 flex flex-row">
        <%= for level <- @levels do %>
          <%= with %Messages{unread: unread} <- Map.fetch!(@messages, level) do %>
            <.level level={level} unread={unread} active_level={@active_tab} />
          <% end %>
        <% end %>
        <form class="flex-1 text-slate-900 ml-2" phx-change="search">
          <input type="text" class="block w-full bg-true-gray-100 rounded border-0 py-1.5 pr-20 text-true-gray-900 ring-1 ring-inset ring-true-gray-500 placeholder:text-true-gray-400 focus:ring-2 focus:ring-inset focus:ring-purple-400 sm:text-sm sm:leading-6 group-[.has-errors]:ring-red-400 max-w-80" value={@active_messages.search} name="search" />
        </form>
      </div>
      <div class="flex-1 p-4 max-h-full h-full overflow-y-auto">
        <%= if Messages.has_messages?(@active_messages) do %>
          <div class="text-right">
            <span class="text-indigo-500 cursor-pointer mr-2" phx-click="collapse-all">Collapse all</span>
            <span class="text-indigo-500 cursor-pointer mr-2" phx-click="expand-all">Expand all</span>
            <span class="text-indigo-500 cursor-pointer" phx-click="clear">Clear</span>
          </div>
          <%= for %{id: id, timestamp: timestamp, message: message, metadata: metadata} <- @active_messages.messages do %>
            <.message uuid={id} timestamp={timestamp} message={message} metadata={metadata} expanded={@active_messages.expanded} />
          <% end %>
        <% else %>
          <div class="w-full text-center text-lg text-true-gray-700 py-4">
            No messages
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  @default_class "flex-initial p-2 mb-2 ml-1 text-sm rounded-sm font-mono"
  defp level(%{level: level, active_level: active_level} = assigns) do
    class =
      if active_level == level do
        @default_class <> " bg-indigo-300 text-slate-900 hover:bg-indigo-300 hover:text-slate-900"
      else
        @default_class <> " hover:bg-true-gray-200"
      end

    assigns = assign(assigns, :class, class)

    ~H"""
    <.link class={@class} patch={~p(/logger?#{[tab: @level]})}>
      <%= @level %>
      <%= if @unread > 0 do %>
        <span class="px-2 py-1 bg-blue-600 text-white text-xs rounded-lg"><%= @unread %></span>
      <% end %>
    </.link>
    """
  end

  defp message(%{uuid: uuid, expanded: expanded, timestamp: timestamp} = assigns) do
    assigns =
      assigns
      |> assign(:expanded?, MapSet.member?(expanded, uuid))
      |> assign(:date, format_date(timestamp))

    ~H"""
    <div class="p-1 px-2 mb-2 bg-true-gray-200">
      <div class="text-xs py-2 font-mono text-true-gray-900"><%= @message %></div>
      <div class="flex flex-row">
        <div class="flex-1 text-indigo-500 cursor-pointer" phx-click="expand" phx-value-uuid={@uuid}><%= if @expanded?, do: "Collapse", else: "Expand" %></div>
        <div class="flex-1 text-right text-xs text-slate-600"><%= @date %></div>
      </div>
      <%= if @expanded? do %>
        <ul class="mt-2">
          <%= for {key, value} <- @metadata do %>
            <.metadata key={key} value={value} />
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  defp metadata(%{value: value} = assigns) do
    assigns = assign(assigns, :pretty_value, prettify_value(value))

    ~H"""
    <li class="mb-1 border-2 border-slate-800 rounded-sm">
      <div class="text-xs px-2 py-1 bg-slate-800 text-true-gray-100 font-mono"><%= @key %></div>
      <pre class="text-sm p-2 overflow-x-auto bg-true-gray-100"><%= Phoenix.HTML.raw(@pretty_value) %></pre>
    </li>
    """
  end
end
