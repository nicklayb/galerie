defmodule GalerieWeb.Core.Notifications.Message do
  defstruct [:id, :type, :key, :message, :clear_timer, params: %{}]

  alias GalerieWeb.Core.Notifications.Message

  def new(type, message, options \\ []) do
    key = Keyword.get(options, :key)
    params = Keyword.get(options, :params, %{})

    schedule_timer(
      %Message{
        id: Ecto.UUID.generate(),
        type: type,
        key: key,
        message: message,
        params: params
      },
      options
    )
  end

  def clear(%Message{clear_timer: clear_timer} = message) do
    if is_reference(clear_timer), do: Process.cancel_timer(clear_timer)
    %Message{message | clear_timer: nil}
  end

  @timers %{
    info: :timer.seconds(8),
    error: 0
  }
  defp schedule_timer(%Message{id: id, type: type} = message, options) do
    timer = Keyword.get_lazy(options, :timer, fn -> Map.fetch!(@timers, type) end)

    if timer > 0 do
      clear_timer =
        options
        |> Keyword.get_lazy(:pid, fn -> self() end)
        |> Process.send_after({:notifications, {:clear, id}}, timer)

      %Message{message | clear_timer: clear_timer}
    else
      message
    end
  end
end
