defmodule GalerieWeb.Logger.Backend do
  @behaviour :gen_event

  require Logger
  alias GalerieWeb.Logger.Config

  @impl :gen_event
  def init(_) do
    config = Config.new()
    {:ok, %{config: config}}
  end

  @impl :gen_event
  def handle_event({_, group_leader, {Logger, _, _, _}}, state)
      when node(group_leader) != node() do
    {:ok, state}
  end

  def handle_event(
        {level, _group_leader, {Logger, message, timestamp, metadata}},
        %{config: config} = state
      ) do
    level = if level == :warn, do: :warning, else: level

    broadcast_message(
      %{level: level, message: to_string(message), timestamp: timestamp, metadata: metadata},
      config
    )

    {:ok, state}
  end

  def handle_event(:flush, state) do
    {:ok, state}
  end

  def handle_event(_, state) do
    {:ok, state}
  end

  @impl :gen_event
  def handle_call(_, state) do
    {:ok, :ok, state}
  end

  @impl :gen_event
  def handle_info({:file_event, _, {_, events}}, state) do
    state =
      if :modified in events do
        map_config(state, &Config.reload_file/1)
      else
        state
      end

    {:ok, state}
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  @impl :gen_event
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  @impl :gen_event
  def terminate(_reason, _state) do
    :ok
  end

  defp broadcast_message(
         %{
           message: message,
           metadata: metadata
         } = params,
         %Config{} = config
       ) do
    if not message_excluded?(message, config) do
      params = Map.put(params, :metadata, filter_out_metadata(metadata, config))
      Config.broadcast(config, {:message, params})
      send_os_notification(params, config)
    end
  end

  defp send_os_notification(
         %{level: level, message: message},
         %Config{os_notify: os_notify} = config
       ) do
    if level in os_notify do
      Config.send_os_notification(config, level, message)
    end
  end

  defp filter_out_metadata(metadata, %Config{hide_metadata: hide_metadata}) do
    Enum.reject(metadata, fn {key, _} -> key in hide_metadata end)
  end

  defp message_excluded?(message, %Config{exclude_patterns: exclude_patterns}) do
    Enum.any?(exclude_patterns, &matches?(&1, message))
  end

  defp matches?(pattern, message) do
    Regex.match?(pattern, message)
  end

  defp map_config(state, function) do
    Map.update!(state, :config, function)
  end
end
