defmodule Galerie.Jobs.ThumbnailGenerator.ConvertRaw do
  alias Galerie.Folder
  alias Galerie.Picture
  alias Galerie.Repo

  @default_quality 80
  def convert(%Picture{fullpath: fullpath} = picture, options \\ []) do
    quality = Keyword.get(options, :quality, @default_quality)
    output_path = Folder.raw_converted_output(fullpath)

    fullpath
    |> autoraw(output_path, quality)
    |> Result.log(
      fn _ -> "[#{inspect(__MODULE__)}] [autoraw] [#{picture.id}] [created]" end,
      &"[#{inspect(__MODULE__)}] [autoraw] [#{picture.id}] [failed] #{inspect(&1)}"
    )
    |> Result.and_then(&update_picture(&1, picture))
    |> Result.log(
      fn _ -> "[#{inspect(__MODULE__)}] [converted_jpeg] [#{picture.id}] [updated]" end,
      &"[#{inspect(__MODULE__)}] [converted_jpeg] [#{picture.id}] [failed] #{inspect(&1)}"
    )
  end

  defp update_picture(converted_jpeg, %Picture{} = picture) do
    picture
    |> Picture.changeset(%{converted_jpeg: converted_jpeg})
    |> Repo.update()
    |> Result.tap(&Galerie.PubSub.broadcast(Picture, {:raw_converted, &1}))
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
