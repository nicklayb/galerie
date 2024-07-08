defmodule Galerie.Directory do
  def raw_converted(fullpath) do
    priv_dir()
    |> Path.join("raw_converted")
    |> Path.join(fullpath)
    |> then(&(&1 <> ".jpg"))
  end

  def raw_converted_output(fullpath) do
    fullpath
    |> raw_converted()
    |> tap(&create_directory_if_missing/1)
  end

  def thumbnail(path) do
    priv_dir()
    |> Path.join("thumbnails")
    |> Path.join(path)
    |> then(&(&1 <> ".jpg"))
  end

  def thumbnail_output(path) do
    path
    |> thumbnail()
    |> tap(&create_directory_if_missing/1)
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
