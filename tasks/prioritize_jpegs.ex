defmodule Tasks.PrioritizeJpegs do
  @moduledoc """
  Task that updates *all* pictures that has a main_picture_id that is not
  the JPEG of the group.
  """
  import Ecto.Query
  require Logger
  alias Galerie.Pictures.Picture
  alias Galerie.Repo

  def run(_) do
    Picture.Group
    |> join(:left, [g], assoc(g, :pictures), as: :pictures)
    |> join(:left, [g], assoc(g, :main_picture), as: :main_picture)
    |> where(
      [pictures: pictures, main_picture: main_picture],
      main_picture.type == :tiff and pictures.type == :jpeg
    )
    |> preload([g, pictures: pictures, main_picture: main_picture],
      pictures: pictures,
      main_picture: main_picture
    )
    |> Repo.all()
    |> Enum.map(&assign_main_picture/1)
  end

  defp assign_main_picture(%Picture.Group{
         id: group_id,
         group_name: group_name,
         pictures: [%Picture{id: new_main_picture_id} | _]
       }) do
    case Galerie.UseCase.execute(Galerie.Pictures.UseCase.SetMainPicture, new_main_picture_id, []) do
      {:ok, _} ->
        Logger.info("[#{inspect(__MODULE__)}] [#{group_id} / #{group_name}] succeess")

      error ->
        Logger.error("[#{inspect(__MODULE__)}] [#{group_id} / #{group_name}] #{inspect(error)}")
    end
  end
end
