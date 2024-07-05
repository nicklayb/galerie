defmodule Galerie.Jobs.ThumbnailGenerator.ConvertRaw do
  alias Galerie.Picture
  alias Galerie.Repo

  @default_quality 80
  def convert(%Picture{fullpath: fullpath} = picture, options \\ []) do
    quality = Keyword.get(options, :quality, @default_quality)
    output_path = permanent_output_path(fullpath)

    with {:ok, converted_path} <- autoraw(fullpath, output_path, quality) do
      picture
      |> Picture.changeset(%{converted_path: converted_path})
      |> Repo.update()
    end
  end

  defp autoraw(input, output, quality) do
    autoraw_binary = autoraw_binary()

    case System.cmd(autoraw_binary, [input, output, to_string(quality)]) do
      {_, 0} ->
        {:ok, output}

      {body, code} ->
        {:error, {code, body}}
    end
  end

  defp autoraw_binary do
    :galerie
    |> Application.get_env(Galerie.Jobs.ThumbnailGenerator.ConvertRaw, [])
    |> Keyword.get(:autoraw_binary, default_binary_location())
  end

  defp permanent_output_path(fullpath) do
    :galerie
    |> :code.priv_dir()
    |> Path.join("raw_converted")
    |> Path.join(fullpath)
    |> tap(&create_directory_if_missing/1)
  end

  defp create_directory_if_missing(path) do
    path
    |> Path.basename()
    |> IO.inspect(label: "Folder")
    |> File.mkdir_p!()
  end

  defp default_binary_location do
    :galerie
    |> :code.priv_dir()
    |> Path.join("scripts/autoraw")
  end
end
