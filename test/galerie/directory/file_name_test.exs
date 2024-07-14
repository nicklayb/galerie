defmodule Galerie.Directory.FileNameTest do
  use Galerie.BaseCase

  alias Galerie.Directory.FileName

  describe "cast/2" do
    test "cast path and folder to file name struct" do
      folder_path = "/home/user/Pictures"
      file_path = Path.join(folder_path, "photos/photo.jpg")

      assert %FileName{
               extension: "jpg",
               group_name: "photos/photo",
               name: "photo",
               original_name: "photos/photo.jpg"
             } == FileName.cast(file_path, folder_path)
    end

    test "cast path and folder to file name struct and rejects folder only once" do
      folder_path = "/home/user/Pictures"
      file_path = Path.join([folder_path, folder_path, "photos/photo.jpg"])

      assert "/home/user/Pictures/home/user/Pictures/photos/photo.jpg" == file_path

      assert %FileName{
               extension: "jpg",
               group_name: "home/user/Pictures/photos/photo",
               name: "photo",
               original_name: "home/user/Pictures/photos/photo.jpg"
             } == FileName.cast(file_path, folder_path)
    end
  end
end
