defmodule Galerie.Folder do
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
end
