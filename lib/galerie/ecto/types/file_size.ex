defmodule Galerie.Ecto.Types.FileSize do
  use Ecto.Type

  alias Galerie.FileSize

  def type, do: :integer

  def cast(string) when is_binary(string) do
    integer = FileSize.parse(string)
    {:ok, FileSize.simplify(integer)}
  rescue
    _ ->
      :error
  end

  def cast(integer) when is_integer(integer), do: {:ok, FileSize.simplify(integer)}

  def cast({amount, unit} = file_size) when is_integer(amount) and is_atom(unit),
    do: {:ok, file_size}

  def cast(_), do: :error

  def load(data) when is_integer(data) do
    file_size = FileSize.simplify(data)
    {:ok, file_size}
  end

  def dump({amount, unit} = file_size) when is_integer(amount) and is_atom(unit),
    do: {:ok, FileSize.to_integer(file_size)}

  def dump(_), do: :error
end
