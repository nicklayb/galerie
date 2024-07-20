defmodule Galerie.Pictures.UseCase.InsertPicture do
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
    case repo.get_by(Group, group_name: group_name) do
      %Group{} = group ->
        {:ok, group}

      nil ->
        %{group_name: group_name, name: name, folder_id: folder_id}
        |> Group.changeset()
        |> repo.insert()
    end
  end

  defp put_main_picture_id(repo, %{
         picture_group: %Group{main_picture_id: nil} = picture_group,
         picture: %Picture{id: picture_id}
       }) do
    picture_group
    |> Group.main_picture_changeset(%{main_picture_id: picture_id})
    |> repo.update()
  end

  defp put_main_picture_id(_repo, %{picture_group: %Group{} = picture_group}) do
    {:ok, picture_group}
  end

  @impl Galerie.UseCase
  def after_run(%{picture_with_group: %Picture{folder_id: folder_id} = picture}, _options) do
    Galerie.PubSub.broadcast({Folder, folder_id}, {:picture_imported, picture})
  end

  @impl Galerie.UseCase
  def return(%{picture_with_group: picture}, _options) do
    picture
  end
end
