defmodule Galerie.Jobs.ThumbnailGenerator.ConvertRaw do
  alias Galerie.Folder
  alias Galerie.Picture
  alias Galerie.Repo

  @default_quality 80
  def convert(%Picture{fullpath: fullpath} = picture, options \\ []) do
    quality = Keyword.get(options, :quality, @default_quality)
    output_path = Folder.raw_converted_output(fullpath)

    with {:ok, converted_jpeg} <- autoraw(fullpath, output_path, quality) do
      picture
      |> Picture.changeset(%{converted_jpeg: converted_jpeg})
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

  defp default_binary_location do
    :galerie
    |> :code.priv_dir()
    |> Path.join("scripts/autoraw")
  end
end
