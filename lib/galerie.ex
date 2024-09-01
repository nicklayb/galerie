defmodule Galerie do
  @type schema_or_id(schema) :: schema | Ecto.UUID.t()

  def schema do
    quote do
      use Ecto.Schema
      @type t :: %__MODULE__{}

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end

  defmacro __using__(type) do
    apply(__MODULE__, type, [])
  end
end
