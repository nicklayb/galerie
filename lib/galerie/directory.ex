defmodule Galerie.Directory do
  alias Galerie.User

  def raw_converted(fullpath) do
    :raw_converted
    |> configured()
    |> Path.join(fullpath)
    |> then(&(&1 <> ".jpg"))
  end

  def raw_converted_output(fullpath) do
    fullpath
    |> raw_converted()
    |> tap(&create_directory_if_missing/1)
  end

  def thumbnail(path) do
    :thumbnail
    |> configured()
    |> Path.join(path)
    |> then(&(&1 <> ".jpg"))
  end

  def thumbnail_output(path) do
    path
    |> thumbnail()
    |> tap(&create_directory_if_missing/1)
  end

  def upload(%User{id: user_id}, file_name), do: upload(user_id, file_name)

  def upload(user_id, file_name) do
    :upload
    |> configured()
    |> Path.join(user_id)
    |> Path.join(file_name)
  end

  def upload_output(user_or_id, file_name) do
    user_or_id
    |> upload(file_name)
    |> tap(&create_directory_if_missing/1)
  end

  defp configured(type) do
    config = Application.get_env(:galerie, Galerie.Directory)

    case Keyword.get(config, type) do
      nil -> default(type)
      "" -> default(type)
      folder -> folder
    end
  end

  defp default(:thumbnail) do
    Path.join(priv_dir(), "thumbnails")
  end

  defp default(:raw_converted) do
    Path.join(priv_dir(), "raw_converted")
  end

  defp default(:upload) do
    Path.join(priv_dir(), "uploads")
  end

  defp create_directory_if_missing(path) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()
  end

  defp priv_dir, do: :code.priv_dir(:galerie)

  def ls_recursive(folder, acc, function) do
    folder = Path.expand(folder)

    folder
    |> File.ls()
    |> ls_recursive(acc, folder, function)
  end

  defp ls_recursive({:ok, files}, acc, folder, function) do
    Enum.reduce(files, acc, fn file, acc ->
      qualified_file = Path.join(folder, file)

      if File.dir?(qualified_file) do
        ls_recursive(qualified_file, acc, function)
      else
        function.({:ok, qualified_file}, acc)
      end
    end)
  end

  defp ls_recursive(error, acc, _, function) do
    function.(error, acc)
  end
end
