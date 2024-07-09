defmodule Galerie.Downloader do
  @moduledoc """
  File downloader, manages the download of one or multiple pictures
  """
  alias Galerie.Picture

  # TODO: Figure a way to remove the /tmp/galerie/[uuid] prefix in files in zip
  @doc """
  When downloading multiple files, the files are copied to a temporary directory
  to make the zip file's path more simpler. The zip is generated in memory then
  the temporary are deleted.
  """
  @spec download([Picture.t()], Picture.path_type()) :: Result.t(binary(), any())
  def download(pictures, type) do
    unique_id = Ecto.UUID.generate()
    temporary_folder = create_temporary_folder(unique_id)
    moved_files = copy_temporary_files(pictures, temporary_folder, type)
    zip_name = "#{unique_id}.zip"

    zip_name
    |> :zip.create(moved_files, [:memory])
    |> Result.map(fn
      {_, binary} -> binary
    end)
    |> tap(fn _ -> File.rm_rf!(temporary_folder) end)
  end

  defp create_temporary_folder(unique_id) do
    folder_path = "/tmp/galerie/#{unique_id}"
    File.mkdir_p!(folder_path)
    folder_path
  end

  defp copy_temporary_files(pictures, temporary_folder, type) do
    Enum.map(pictures, fn picture ->
      picture
      |> copy_temporary_file(temporary_folder, type)
      |> String.to_charlist()
    end)
  end

  defp copy_temporary_file(
         %Picture{folder_id: folder_id} = picture,
         temporary_folder,
         type
       ) do
    picture_path = Picture.path(picture, type)
    filename = Path.basename(picture_path)

    new_path =
      temporary_folder
      |> Path.join(folder_id)
      |> tap(&File.mkdir_p!/1)
      |> Path.join(filename)

    File.cp!(picture_path, new_path)

    new_path
  end
end
