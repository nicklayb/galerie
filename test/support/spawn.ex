defmodule NectarineTest.Support.Spawn do
  @moduledoc """
  Helper module to quickly spawn processes.
  """

  @doc """
  Spawns a process that subscribes to the given PubSub topic

  ## Examples

      iex> Spawn.subscriber(Nectarine.User)
      iex> Nectarine.PubSub.broadcast(Nectarine.User, :hello)

  The code above should output a IO.inspect message with the received
  PubSub message.
  """
  @spec subscriber(Nectarine.PubSub.topic(), function() | nil) :: pid()
  def subscriber(topic, function \\ nil) do
    receiver(fn -> Nectarine.PubSub.subscribe(topic) end, function)
  end

  @doc "Spawns a process that awaits message after calling a given function"
  @spec receiver(function(), function()) :: pid()
  def receiver(pre_receive, function) do
    spawn(fn ->
      pre_receive.()

      await(function)
    end)
  end

  defp await(function) do
    receive do
      :kill ->
        :ok

      message ->
        function.(message)
        await(function)
    end
  end
end
