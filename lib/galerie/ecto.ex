defmodule Galerie.Ecto do
  def check_uuid(binary_id) do
    case Ecto.UUID.cast(binary_id) do
      :error ->
        {:error, :invalid_binary_id}

      {:ok, uuid} ->
        {:ok, uuid}
    end
  end
end
