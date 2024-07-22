defmodule Galerie.Editor.Manager do
  use GenServer
  alias Galerie.Editor.Transform
  alias Galerie.Pictures.Picture
  alias Galerie.Pictures.Picture.Group
  alias Galerie.Repo

  def start_link(args) do
    name = Keyword.fetch!(args, :name)
    group_id = Keyword.fetch!(args, :group_id)
    user_id = Keyword.fetch!(args, :user_id)

    GenServer.start_link(__MODULE__, [group_id: group_id, user_id: user_id], name: name)
  end

  def init(args) do
    group =
      args
      |> Keyword.fetch!(:group_id)
      |> then(&Repo.get!(Group, &1))
      |> Repo.preload([:main_picture])

    picture_reference = open_image(group)

    state =
      %{transformations: []}
      |> put_group(group)
      |> put_reference(picture_reference)

    {:ok, state}
  end

  defp open_image(%Group{main_picture: main_picture}) do
    main_picture
    |> Picture.path(:jpeg)
    |> Image.open!()
  end

  def handle_call(
        {:transform, transformation},
        _,
        %{picture_reference: picture_reference} = state
      ) do
    state =
      case Transform.transform(picture_reference, transformation) do
        {:ok, new_reference} ->
          state
          |> put_reference(new_reference)
          |> put_transformation(transformation)

        _ ->
          state
      end

    {:reply, state.transformations, state}
  end

  def handle_call(:image, _, %{picture_reference: picture_reference} = state) do
    binary = Image.write!(picture_reference, :memory, suffix: ".jpg")

    {:reply, binary, state}
  end

  defp put_reference(state, reference) do
    Map.put(state, :picture_reference, reference)
  end

  defp put_transformation(%{transformations: _} = state, transformation) do
    Map.update!(state, :transformations, &[transformation | &1])
  end

  defp put_group(state, group) do
    Map.put(state, :group, group)
  end
end
