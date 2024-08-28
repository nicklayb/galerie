defmodule Galerie.Pictures.UseCase.EditPictures do
  use Galerie.UseCase

  require Ecto.Query

  alias Galerie.Accounts.User
  alias Galerie.Albums.AlbumPictureGroup
  alias Galerie.Form.Pictures.EditPicturesForm
  alias Galerie.Pictures.Picture

  @impl Galerie.UseCase
  def validate(%EditPicturesForm{} = form, _) do
    {:ok, form}
  end

  @impl Galerie.UseCase
  def run(
        multi,
        %EditPicturesForm{} = form,
        _options
      ) do
    form.group_ids
    |> Enum.reduce(multi, fn group_id, multi ->
      multi
      |> add_to_albums(group_id, form.album_ids)
      |> update_metadatas(group_id, form.metadatas)
    end)
    |> assign_updated_metadatas(form.metadatas)
  end

  defp assign_updated_metadatas(%Ecto.Multi{} = multi, %EditPicturesForm.Metadatas{} = metadatas) do
    Ecto.Multi.put(
      multi,
      :updated_metadata,
      EditPicturesForm.Metadatas.edited_metadata(metadatas)
    )
  end

  defp add_to_albums(%Ecto.Multi{} = multi, group_id, album_ids) do
    Enum.reduce(album_ids, multi, fn album_id, multi ->
      insert_if_missing(multi, group_id, album_id)
    end)
  end

  defp insert_if_missing(%Ecto.Multi{} = multi, group_id, album_id) do
    Ecto.Multi.run(multi, {:album, group_id, album_id}, fn repo, _changes ->
      query =
        Ecto.Query.where(
          AlbumPictureGroup,
          [apg],
          apg.album_id == ^album_id and apg.group_id == ^group_id
        )

      if repo.exists?(query) do
        {:ok, nil}
      else
        %{album_id: album_id, group_id: group_id}
        |> AlbumPictureGroup.changeset()
        |> repo.insert()
      end
    end)
  end

  defp update_metadatas(%Ecto.Multi{} = multi, group_id, metadatas) do
    query =
      Picture.Metadata
      |> Ecto.Query.join(:left, [metadata], picture in assoc(metadata, :picture), as: :picture)
      |> Ecto.Query.where([picture: picture], picture.group_id == ^group_id)

    multi
    |> Ecto.Multi.all({:group, group_id}, query)
    |> Ecto.Multi.run({:updated_metadata, group_id}, fn repo, changes ->
      changes
      |> Map.fetch!({:group, group_id})
      |> Enum.reduce_while({:ok, %{}}, fn metadata, {:ok, acc} ->
        changeset =
          Picture.Metadata.manual_edit_changeset(metadata, Map.from_struct(metadatas))

        case repo.update(changeset) do
          {:ok, metadata} ->
            {:cont, {:ok, Map.put(acc, metadata.id, metadata)}}

          error ->
            {:halt, error}
        end
      end)
    end)
  end

  @impl Galerie.UseCase
  def after_run(%{updated_metadata: updated_metadata} = multi_output, options) do
    with %User{} = user <- Keyword.get(options, :user) do
      Galerie.PubSub.broadcast(user, {:metadata_updated, updated_metadata})
    end

    Enum.map(multi_output, fn
      {{:updated_metadata, group_id}, _} ->
        Galerie.PubSub.broadcast(
          {Picture.Group, group_id},
          {:metadata_updated, {updated_metadata, group_id}}
        )

      _ ->
        :noop
    end)
  end

  @impl Galerie.UseCase
  def return(multi_output, _) do
    Enum.reduce(multi_output, [], fn
      {:updated_group, group}, acc ->
        [group | acc]

      _, acc ->
        acc
    end)
  end
end
