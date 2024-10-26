defmodule Galerie.TaskDebouncer do
  use GenServer

  @name Galerie.TaskDebouncer
  def start_link(args) do
    GenServer.start_link(__MODULE__, [], name: Keyword.get(args, :name, @name))
  end

  def debounce(pid \\ @name, identifier, function_spec, options) do
    GenServer.cast(pid, {:schedule, identifier, function_spec, options})
  end

  @default_debounce_timer :timer.seconds(1)
  def init(args) do
    {:ok,
     %{calls: %{}, debounce_timer: Keyword.get(args, :debounce_timer, @default_debounce_timer)}}
  end

  def handle_cast({:schedule, identifier, function_spec, options}, state) do
    state = debounce_function_call(state, identifier, function_spec, options)
    {:noreply, state}
  end

  def handle_info({:call, identifier, {module, function, arguments}}, state) do
    apply(module, function, arguments)
    state = Map.update!(state, :calls, &Map.delete(&1, identifier))
    {:noreply, state}
  end

  defp debounce_function_call(
         %{debounce_timer: debounce_timer} = state,
         identifier,
         function_spec,
         options
       ) do
    cancel_previous_timer(state, identifier)

    new_value =
      schedule_call(identifier, function_spec, Keyword.get(options, :timeout, debounce_timer))

    Map.update!(state, :calls, &Map.put(&1, identifier, new_value))
  end

  defp cancel_previous_timer(%{calls: calls}, identifier) do
    with {previous_timer, _} <- Map.get(calls, identifier) do
      Process.cancel_timer(previous_timer)
    end
  end

  defp schedule_call(identifier, function_spec, debounce_timer) do
    timer = Process.send_after(self(), {:call, identifier, function_spec}, debounce_timer)
    {timer, function_spec}
  end
end
