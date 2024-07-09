defmodule Galerie.Downloader do
  alias Galerie.Picture

  # TODO: Figure a way to remove the /tmp/galerie/[uuid] prefix in files in zip
  def download(pictures) do
    unique_id = Ecto.UUID.generate()
    temporary_folder = create_temporary_folder(unique_id)
    moved_files = copy_temporary_files(pictures, temporary_folder)
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

  defp copy_temporary_files(pictures, temporary_folder) do
    Enum.map(pictures, fn picture ->
      picture
      |> copy_temporary_file(temporary_folder)
      |> String.to_charlist()
    end)
  end

  defp copy_temporary_file(
         %Picture{fullpath: fullpath, original_name: name, folder_id: folder_id},
         temporary_folder
       ) do
    new_path =
      temporary_folder
      |> Path.join(folder_id)
      |> tap(&File.mkdir_p!/1)
      |> Path.join(name)

    File.cp!(fullpath, new_path)

    new_path
  end
end
