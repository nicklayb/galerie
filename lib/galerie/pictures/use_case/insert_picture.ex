defmodule Galerie.Pictures.UseCase.InsertPicture do
  @moduledoc """
  Use case to import pictures in the database. If the picture already has 
  a group existing (another file with exact same name and path but different
  extension) it'll be reused or a new one will be created.

  If a given group includes a JPG, this one will be prioritized as main picture
  since they will probably more inlined with what the photographer saw when
  shooting since the raw is converted.
  """
  use Galerie.UseCase
  alias Galerie.Folders.Folder
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Group

  @impl Galerie.UseCase
  def run(multi, params, _options) do
    multi
    |> Ecto.Multi.insert(:picture, Picture.create_changeset(params))
    |> Ecto.Multi.run(:picture_group, &get_or_create_group/2)
    |> Ecto.Multi.update(:picture_with_group, fn %{
                                                   picture_group: %Group{id: group_id},
                                                   picture: %Picture{} = picture
                                                 } ->
      Picture.group_changeset(picture, %{group_id: group_id})
    end)
    |> Ecto.Multi.run(:group_with_main_picture, &put_main_picture_id/2)
  end

  defp get_or_create_group(
         repo,
         %{
           picture: %Picture{
             name: name,
             group_name: group_name,
             folder_id: folder_id
           }
         }
       ) do
    Group
    |> repo.get_by(group_name: group_name)
    |> Result.from_nil()
    |> Result.with_default(fn ->
        %{group_name: group_name, name: name, folder_id: folder_id}
        |> Group.changeset()
        |> repo.insert!()
    end)
    |> repo.preload([:main_picture])
    |> Result.succeed()
  end

  defp put_main_picture_id(repo, %{
         picture_group: %Group{main_picture_id: main_picture_id} = picture_group,
         picture: %Picture{id: picture_id} = picture
       }) do
    if is_nil(main_picture_id) or prioritized?(picture, picture_group.main_picture) do
    picture_group
    |> Group.main_picture_changeset(%{main_picture_id: picture_id})
    |> repo.update()
    else
      {:ok, picture_group}
    end
  end

  @impl Galerie.UseCase
  def after_run(%{picture_with_group: %Picture{folder_id: folder_id} = picture}, _options) do
    Galerie.PubSub.broadcast({Folder, folder_id}, {:picture_imported, picture})
  end

  @impl Galerie.UseCase
  def return(%{picture_with_group: picture}, _options) do
    picture
  end

  defp prioritized?(%Picture{type: :jpeg}, %Picture{type: :tiff}), do: true
  defp prioritized?(%Picture{}, %Picture{}), do: false
end
