defmodule Galerie.Directory.FileName do
  defstruct [:extension, :original_name, :name, :group_name]

  alias Galerie.Directory.FileName

  @type picture_type :: :jpeg | :tiff

  @type t :: %FileName{
          extension: String.t(),
          original_name: String.t(),
          name: String.t(),
          group_name: String.t()
        }

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
