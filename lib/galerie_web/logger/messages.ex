defmodule GalerieWeb.Logger.Messages do
  defstruct [:messages, :expanded, :search, :max_messages, unread: 0]

  alias GalerieWeb.Logger.Messages

  @type message :: map()
  @type message_id :: String.t()
  @type message_timestamp ::
          {{non_neg_integer(), non_neg_integer(), non_neg_integer()},
           {non_neg_integer(), non_neg_integer(), non_neg_integer(), non_neg_integer()}}
  @type message_content :: String.t()
  @type message_metadata :: Keyword.t()

  @type t :: %Messages{
          messages: [message()],
          expanded: MapSet.t(message_id()),
          search: String.t() | nil,
          unread: non_neg_integer()
        }

  @max_messages 100

  def new(args \\ []) do
    max_messages = Keyword.get(args, :max_messages, @max_messages)

    %Messages{
      messages: [],
      expanded: MapSet.new(),
      max_messages: max_messages
    }
  end

  @spec update_search(t(), String.t()) :: t()
  def update_search(%Messages{search: search} = messages, search), do: messages

  def update_search(%Messages{} = messages, search) do
    map_search(messages, fn _ ->
      case String.trim(search) do
        "" -> nil
        search -> search
      end
    end)
  end

  @spec toggle(t(), message_id()) :: t()
  def toggle(%Messages{} = messages, message_id) do
    map_expanded(messages, fn expanded ->
      if MapSet.member?(expanded, message_id) do
        MapSet.delete(expanded, message_id)
      else
        MapSet.put(expanded, message_id)
      end
    end)
  end

  @spec collapse_all(t()) :: t()
  def collapse_all(%Messages{} = messages) do
    map_expanded(messages, MapSet.new())
  end

  @spec expand_all(t()) :: t()
  def expand_all(%Messages{messages: inner_messages} = messages) do
    map_expanded(messages, fn current_messages ->
      Enum.reduce(inner_messages, current_messages, fn current, acc ->
        MapSet.put(acc, message_id(current))
      end)
    end)
  end

  @spec clear_messages(t()) :: t()
  def clear_messages(%Messages{} = messages) do
    messages
    |> map_messages([])
    |> map_expanded(MapSet.new())
  end

  @spec clear_unread(t()) :: t()
  def clear_unread(%Messages{} = messages), do: %Messages{messages | unread: 0}

  @spec put_message(t(), message_timestamp(), message_content(), message_metadata()) :: t()
  def put_message(%Messages{} = messages, timestamp, message, metadata) do
    message = build_message(timestamp, message, metadata)

    map_messages(messages, &[message | &1])
  end

  @spec has_messages?(t()) :: boolean()
  def has_messages?(%Messages{messages: []}), do: false
  def has_messages?(%Messages{}), do: true

  @spec visible_messages(t()) :: t()
  def visible_messages(%Messages{search: nil} = messages), do: messages

  def visible_messages(%Messages{search: search} = messages) do
    map_messages(messages, fn inner_messages ->
      Enum.filter(inner_messages, &matches?(&1, search))
    end)
  end

  defp matches?(message, search) do
    message
    |> message_content()
    |> String.downcase()
    |> String.contains?(search)
  end

  @spec increment(t()) :: t()
  def increment(%Messages{max_messages: max_messages} = messages) do
    map_unread(messages, fn
      unread when unread < max_messages ->
        unread + 1

      unread ->
        unread
    end)
  end

  defp map_messages(%Messages{messages: inner_messages} = messages, function)
       when is_function(function, 1) do
    map_messages(messages, function.(inner_messages))
  end

  defp map_messages(%Messages{max_messages: max_messages} = messages, inner_messages) do
    %Messages{messages | messages: Enum.take(inner_messages, max_messages)}
  end

  defp map_unread(%Messages{unread: unread} = messages, function) when is_function(function, 1) do
    map_unread(messages, function.(unread))
  end

  defp map_unread(%Messages{} = messages, unread) do
    %Messages{messages | unread: unread}
  end

  defp map_expanded(%Messages{expanded: expanded} = messages, function)
       when is_function(function, 1) do
    map_expanded(messages, function.(expanded))
  end

  defp map_expanded(%Messages{} = messages, expanded) do
    %Messages{messages | expanded: expanded}
  end

  defp map_search(%Messages{search: search} = messages, function) when is_function(function, 1) do
    map_search(messages, function.(search))
  end

  defp map_search(%Messages{} = messages, nil) do
    %Messages{messages | search: nil}
  end

  defp map_search(%Messages{} = messages, search) do
    %Messages{messages | search: String.downcase(search)}
  end

  defp message_id(%{id: id}), do: id

  defp message_content(%{message: message}), do: message

  defp build_message(timestamp, message, metadata),
    do: %{id: Ecto.UUID.generate(), timestamp: timestamp, message: message, metadata: metadata}
end
