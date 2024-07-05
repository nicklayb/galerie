defmodule Galerie.PubSub.Message do
  @moduledoc """
  Pub sub message wrapping structure
  """
  defstruct [:message, :params, :from, :topic]

  alias Galerie.PubSub.Message

  @type message :: atom()
  @type input_message :: atom() | {message(), any()}
  @type t :: %Message{message: message(), params: any(), from: pid(), topic: String.t()}

  @doc "Builds a pub sub message"
  @spec new(message(), pid(), String.t()) :: t()
  def new(message, from, topic) do
    {message, params} =
      case message do
        {message, params} -> {message, params}
        message when is_atom(message) -> {message, nil}
      end

    %Message{message: message, params: params, topic: topic, from: from}
  end
end
