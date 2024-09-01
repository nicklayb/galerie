defmodule Galerie.Directory.FileName do
  @moduledoc """
  Structure to work with parsed filename.
  """
  defstruct [:extension, :original_name, :name, :group_name]

  alias Galerie.Directory.FileName

  @type picture_type :: :jpeg | :tiff

  @type t :: %FileName{
          extension: String.t(),
          original_name: String.t(),
          name: String.t(),
          group_name: String.t()
        }

  @doc """
  Casts a filepath with the folder path to a structure.

  When given a path that is *not* the full file's path,
  the remaining path will be part of the filename. This
  is because we want to distinguish file with the same 
  name in different folder.

  ## Example

  Take the following example, persisting the three DSC0001.JPG
  files implies keeping the parent folder in the file name
  otherwise they won't be distinguishable fom one another.

      /root
      |-- /pictures
          |-- /camera_1
              |-- /DSC0001.JPG
          |-- /camera_2
              |-- /DSC0001.JPG
          |-- /camera_3
              |-- /DSC0001.JPG
  """
  @spec cast(String.t(), String.t()) :: t()
  def cast(path, folder_path) do
    original_name =
      path
      |> String.replace(folder_path, "", global: false)
      |> String.trim_leading("/")

    filename = Path.basename(path)

    extension =
      filename
      |> Path.extname()
      |> String.trim_leading(".")

    group_name =
      String.trim_trailing(original_name, "." <> extension)

    %FileName{
      extension: extension,
      original_name: original_name,
      name: String.replace(filename, ".#{extension}", ""),
      group_name: group_name
    }
  end
end
