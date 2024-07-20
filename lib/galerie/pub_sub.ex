defmodule Galerie.PubSub do
  @moduledoc """
  Galerie's pub sub module uses a custom Dispatcher to wrap
  every message in a `%Galerie.PubSub.Message{}` structure
  to make them easily distinguishable from other mesages
  """
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

  @doc "Broadcasts a message to one or more topics"
  @spec broadcast(topic() | [topic()] | String.t(), message()) :: :ok
  def broadcast(topics, message) when is_list(topics) do
    Enum.each(topics, &broadcast(&1, message))
  end

  def broadcast(topic, message) when is_binary(topic) do
    Phoenix.PubSub.broadcast(Galerie.PubSub, topic, {topic, message}, @dispatcher)
  end

  def broadcast(topic, message) do
    topic
    |> topic()
    |> broadcast(message)
  end

  @doc "Subscribes to one or more topics"
  @spec subscribe(topic() | [topic()] | String.t()) :: :ok
  def subscribe(topics) when is_list(topics) do
    Enum.each(topics, &subscribe/1)
  end

  def subscribe(topic) when is_binary(topic) do
    Phoenix.PubSub.subscribe(Galerie.PubSub, topic)
  end

  def subscribe(topic) do
    topic
    |> topic()
    |> subscribe()
  end

  @doc "Unsubscribes to one or more topics"
  @spec unsubscribe(topic() | [topic()] | String.t()) :: :ok
  def unsubscribe(topics) when is_list(topics) do
    Enum.each(topics, &unsubscribe/1)
  end

  def unsubscribe(topic) when is_binary(topic) do
    Phoenix.PubSub.unsubscribe(Galerie.PubSub, topic)
  end

  def unsubscribe(topic) do
    topic
    |> topic()
    |> unsubscribe()
  end

  @doc "Dispatches a wrapped message to the receipients"
  @spec dispatch([pid()], pid(), {String.t(), message()}) :: :ok
  def dispatch(entries, from, {topic, message}) do
    message = Message.new(message, from, topic)

    Phoenix.PubSub.dispatch(entries, from, message)
  end
end
