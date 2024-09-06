defmodule GalerieWeb.Logger.Config do
  defstruct [
    :pub_sub_server,
    :config_file,
    :file_watcher_pid,
    topic: "live_logger",
    exclude_patterns: [],
    hide_metadata: [],
    os_notify: []
  ]

  alias GalerieWeb.Logger.Config

  @type t :: %Config{
          pub_sub_server: module(),
          config_file: String.t() | nil,
          file_watcher_pid: pid() | nil,
          topic: String.t(),
          exclude_patterns: [Regex.t()],
          hide_metadata: [atom()],
          os_notify: [atom()]
        }
  @json_keys ~w(exclude_patterns hide_metadata os_notify)a

  @spec new :: t()
  def new do
    :logger
    |> Application.get_env(GalerieWeb.Logger.Backend)
    |> new()
  end

  @spec new(Keyword.t()) :: t()
  def new(config) do
    config = load_from_file(config)

    Config
    |> struct(config)
    |> validate!()
  end

  @spec reload_file(t()) :: t()
  def reload_file(%Config{file_watcher_pid: pid} = config)
      when is_pid(pid) do
    config =
      config
      |> Map.from_struct()
      |> Map.to_list()
      |> config_from_file()

    log_info("Config reloaded")

    struct(Config, config)
  end

  def reload_file(config), do: config

  @spec subscribe() :: any()
  def subscribe do
    config = application_config()

    Config
    |> struct(config)
    |> subscribe()
  end

  @spec subscribe(t()) :: any()
  def subscribe(%Config{pub_sub_server: pub_sub_server, topic: topic} = config) do
    if pub_sub_alive?(config) do
      Phoenix.PubSub.subscribe(pub_sub_server, topic)
    end
  end

  @spec broadcast(t(), any()) :: any()
  def broadcast(%Config{pub_sub_server: pub_sub_server, topic: topic} = config, message) do
    if pub_sub_alive?(config) do
      Phoenix.PubSub.broadcast(pub_sub_server, topic, message)
    end
  end

  @spec send_os_notification(t(), any(), any()) :: any()
  def send_os_notification(%Config{}, level, message) do
    case :os.type() do
      {:unix, :linux} ->
        System.cmd("notify-send", [to_string(level), message])

      other ->
        log_error("Unable to send system notification on os #{inspect(other)}")
    end
  end

  defp validate!(%Config{pub_sub_server: nil}),
    do: raise("Expected :pub_sub_server` to be configured on the Logger backend")

  defp validate!(config), do: config

  defp load_from_file(config) do
    case Keyword.get(config, :config_file) do
      nil ->
        config

      file_path ->
        config_file = Path.expand(file_path)

        config
        |> Keyword.put(:config_file, config_file)
        |> config_from_file()
        |> watch_file(config_file)
    end
  end

  defp config_from_file(config) do
    file_path = Keyword.fetch!(config, :config_file)

    case read_file(file_path) do
      {:ok, json} ->
        Keyword.merge(config, to_config(json))

      _ ->
        config
    end
  end

  defp read_file(file_path) do
    with {:file, {:ok, content}} <- {:file, File.read(file_path)},
         {:json, {:ok, %{} = json}} <- {:json, Jason.decode(content)} do
      {:ok, json}
    else
      {:file, {:error, error}} ->
        log_error("file #{file_path} could be read, error: #{inspect(error)}")

      {:json, {:error, error}} ->
        log_error("file #{file_path} is not valid JSON, error: #{inspect(error)}")
    end
  end

  defp to_config(json) do
    Enum.reduce(@json_keys, [], fn key, acc ->
      case Map.get(json, to_string(key), :undefined) do
        :undefined ->
          acc

        value ->
          Keyword.put(acc, key, to_config(key, value))
      end
    end)
  end

  defp to_config(:exclude_patterns, patterns) do
    Enum.reduce(patterns, [], fn pattern, acc ->
      case Regex.compile(pattern) do
        {:ok, %Regex{} = regex} ->
          [regex | acc]

        {:error, error} ->
          log_error("pattern `#{pattern}` could not be compiled, error: #{inspect(error)}")

          acc
      end
    end)
  end

  defp to_config(config_key, keys) when config_key in ~w(hide_metadata os_notify)a do
    Enum.map(keys, &String.to_atom/1)
  end

  defp watch_file(config, file_path) do
    case FileSystem.start_link(dirs: [file_path]) do
      {:ok, pid} ->
        FileSystem.subscribe(pid)
        Keyword.put(config, :file_watcher_pid, pid)

      {:error, error} ->
        log_error("unable to watch file, error: #{error}")
    end
  end

  defp log_info(message) do
    IO.puts("\e[32m#{inspect(__MODULE__)} #{message} \e[0m")
  end

  defp log_error(message) do
    IO.puts(:stderr, "\e[31m#{inspect(__MODULE__)} #{message} \e[0m")
  end

  defp pub_sub_alive?(%Config{pub_sub_server: pub_sub_server}) do
    case Process.whereis(pub_sub_server) do
      pid when is_pid(pid) ->
        Process.alive?(pid)

      _ ->
        false
    end
  end

  defp application_config, do: Application.get_env(:logger, GalerieWeb.Logger.Backend)
end
