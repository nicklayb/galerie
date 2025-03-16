defmodule Galerie.PubSub do
  use Box.PubSub

  def put_default_options(options) do
    Keyword.put(options, :topic_generator, &topic/1)
  end

  @type topic :: atom() | tuple() | struct()

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

  def topic(binary) when is_binary(binary), do: binary
end
