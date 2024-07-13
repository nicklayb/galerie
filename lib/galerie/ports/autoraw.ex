defmodule Galerie.Ports.Autoraw do
  @moduledoc """
  Converts RAW file to JPEG by invoking the `autoraw` script.

  The script requires the following dependencies:

  - `dcraw`
  - `imagemagick`
  """
  use GenServer

  require Logger

  @type option :: {:quality, non_neg_integer()}

  # TODO: Figure a way to ensure the Autoraw scripts are killed with the Elixir app.
  @spec execute(String.t(), String.t(), [option()]) :: Result.t(String.t(), any())
  def execute(input, output, options \\ []) do
    quality = Keyword.fetch!(options, :quality)

    __MODULE__
    |> GenServer.start_link(input: input, output: output, quality: quality)
    |> Result.and_then(fn pid ->
      :started = GenServer.call(pid, :execute)

      await_completion(pid, output)
    end)
  end

  defp await_completion(pid, output) do
    case GenServer.call(pid, :status) do
      :started ->
        await_completion(pid, output)

      :running ->
        await_completion(pid, output)

      :completed ->
        GenServer.stop(pid)
        {:ok, output}

      {:failed, error} ->
        GenServer.stop(pid)
        {:error, error}
    end
  end

  def init(args) do
    input = Keyword.fetch!(args, :input)
    output = Keyword.fetch!(args, :output)
    quality = Keyword.fetch!(args, :quality)

    Process.flag(:trap_exit, true)

    {:ok, %{input: input, output: output, quality: quality}}
  end

  def handle_info({port, {:data, data}}, %{port: port, input: input} = state) do
    Logger.debug("[#{inspect(__MODULE__)}] [#{input}] [data] #{data}")
    {:noreply, state}
  end

  def handle_info({port, :connected}, %{port: port, input: input} = state) do
    Logger.info("[#{inspect(__MODULE__)}] [#{input}] [connected]")
    {:noreply, Map.put(state, :status, :running)}
  end

  def handle_info({port, :closed}, %{port: port, input: input} = state) do
    Logger.info("[#{inspect(__MODULE__)}] [#{input}] [closed]")
    {:noreply, Map.put(state, :status, :completed)}
  end

  def handle_info({:EXIT, port, :normal}, %{port: port} = state) do
    send(self(), {port, :closed})
    {:noreply, state}
  end

  def handle_info({:EXIT, port, error}, %{port: port} = state) do
    {:noreply, Map.put(state, :status, {:failed, error})}
  end

  def handle_call(:status, _, state) do
    {:reply, state.status, state}
  end

  def handle_call(:execute, _, %{input: input, output: output, quality: quality} = state) do
    port =
      Port.open({:spawn_executable, autoraw_binary()}, [
        :use_stdio,
        args: [input, output, to_string(quality)]
      ])

    state =
      state
      |> Map.put(:port, port)
      |> Map.put(:status, :started)

    {:reply, state.status, state}
  end

  defp autoraw_binary do
    :galerie
    |> Application.get_env(Galerie.Jobs.ThumbnailGenerator.ConvertRaw, [])
    |> Keyword.get(:autoraw_binary, default_binary_location())
  end

  defp default_binary_location do
    :galerie
    |> :code.priv_dir()
    |> Path.join("scripts/autoraw")
  end
end
