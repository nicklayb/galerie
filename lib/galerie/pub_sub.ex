defmodule Galerie.PubSub do
  @moduledoc """
  Galerie's pub sub module uses a custom Dispatcher to wrap
  every message in a `%Galerie.PubSub.Message{}` structure
  to make them easily distinguishable from other mesages
  """
  require Logger
  alias Galerie.PubSub.Message

  @dispatcher Galerie.PubSub

  @type topic :: atom() | tuple()
  @type message :: Message.input_message()

  @doc "Topic generators"
  @spec topic(topic()) :: String.t()
  def topic(%struct{id: id}), do: topic({struct, id})

  def topic(atom) when is_atom(atom) do
    if function_exported?(atom, :__schema__, 1) do
      atom.__schema__(:source)
    else
      to_string(atom)
    end
  end

  def topic({namespace, id}), do: "#{topic(namespace)}:#{id}"
  def topic({namespace, id, child}), do: "#{topic({namespace, id})}:#{child}"

  defmacro broadcast(topics, function_or_message) do
    quote do
      Galerie.PubSub.broadcast(__MODULE__, unquote(topics), unquote(function_or_message))
    end
  end

  @doc "Broadcasts a message to one or more topics"
  @spec broadcast(module(), topic() | [topic()] | String.t(), message() | function()) :: :ok
  def broadcast(module, topics, function) when is_function(function, 0) do
    Task.start(fn ->
      result = function.()

      broadcast(module, topics, result)
    end)

    :ok
  end

  def broadcast(module, topics, message) when is_list(topics) do
    Enum.each(topics, &broadcast(module, &1, message))
  end

  def broadcast(module, topic, message) when is_binary(topic) do
    Logger.debug(
      "[#{inspect(__MODULE__)}] [#{inspect(module)}] [#{topic}] [broadcast] #{inspect(message)}"
    )

    Phoenix.PubSub.broadcast(Galerie.PubSub, topic, {topic, message}, @dispatcher)
  end

  def broadcast(module, topic, message) do
    topic
    |> topic()
    |> then(&broadcast(module, &1, message))
  end

  defmacro subscribe(topics) do
    quote do
      Galerie.PubSub.subscribe(__MODULE__, unquote(topics))
    end
  end

  @doc "Subscribes to one or more topics"
  @spec subscribe(module(), topic() | [topic()] | String.t()) :: :ok
  def subscribe(module, topics) when is_list(topics) do
    Enum.each(topics, &subscribe(module, &1))
  end

  def subscribe(module, topic) when is_binary(topic) do
    Logger.debug("[#{inspect(__MODULE__)}] [#{inspect(module)}] [#{topic}] [subscribe]")
    Phoenix.PubSub.subscribe(Galerie.PubSub, topic)
  end

  def subscribe(module, topic) do
    topic
    |> topic()
    |> then(&subscribe(module, &1))
  end

  defmacro unsubscribe(topics) do
    quote do
      Galerie.PubSub.unsubscribe(__MODULE__, unquote(topics))
    end
  end

  @doc "Unsubscribes to one or more topics"
  @spec unsubscribe(module(), topic() | [topic()] | String.t()) :: :ok
  def unsubscribe(module, topics) when is_list(topics) do
    Enum.each(topics, &unsubscribe(module, &1))
  end

  def unsubscribe(module, topic) when is_binary(topic) do
    Logger.debug("[#{inspect(__MODULE__)}] [#{inspect(module)}] [#{topic}] [unsubscribe]")
    Phoenix.PubSub.unsubscribe(Galerie.PubSub, topic)
  end

  def unsubscribe(module, topic) do
    topic
    |> topic()
    |> then(&unsubscribe(module, &1))
  end

  @doc "Dispatches a wrapped message to the receipients"
  @spec dispatch([pid()], pid(), {String.t(), message()}) :: :ok
  def dispatch(entries, from, {topic, message}) do
    message = Message.new(message, from, topic)

    Phoenix.PubSub.dispatch(entries, from, message)
  end
end
