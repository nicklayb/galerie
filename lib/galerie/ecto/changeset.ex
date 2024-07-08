defmodule Galerie.Ecto.Changeset do
  import Ecto.Changeset

  @type touch_timestamp_option :: {:key, atom()} | {:setter, atom()}

  @doc """
  Updates a schema's timestamp from a boolean field. The schema
  needs to have a virtual field to check if it should update the
  timestamp or not.

  By default, the function infers the timestamp field's name from
  the virtual field's name.

  ## Example

  Calling `touch_timestamp(changeset, setter: :inverted)` will
  attempt to update the `inverted_at` timestamp. This can be
  overriden with thie `:key` option
  """
  @spec touch_timestamp(Ecto.Changeset.t(), [touch_timestamp_option()]) :: Ecto.Changeset.t()
  def touch_timestamp(%Ecto.Changeset{} = changeset, options) do
    Galerie.Ecto.Changeset.update_valid(changeset, fn changeset ->
      setter = Keyword.fetch!(options, :setter)
      key = Keyword.get_lazy(options, :key, fn -> String.to_existing_atom("#{setter}_at") end)

      case get_change(changeset, setter) do
        true -> put_change(changeset, key, DateTime.truncate(DateTime.utc_now(), :second))
        false -> put_change(changeset, key, nil)
        _ -> changeset
      end
    end)
  end

  @doc "Hashes a value using Argon2"
  @spec hash(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def hash(%Ecto.Changeset{} = changeset, field) do
    Galerie.Ecto.Changeset.update_valid(changeset, fn changeset ->
      update_change(changeset, field, &Argon2.hash_pwd_salt/1)
    end)
  end

  @doc "Formats a changeset error"
  @spec format_error({atom(), {String.t(), Keyword.t()}} | {String.t(), Keyword.t()}) ::
          String.t()
  def format_error({_field_name, {_message, _options} = error}), do: format_error(error)

  def format_error({message, options}) do
    case Keyword.get(options, :count) do
      nil ->
        Gettext.dgettext(GalerieWeb.Gettext, "errors", message, options)

      count ->
        Gettext.dngettext(GalerieWeb.Gettext, "errors", message, message, count, options)
    end
  end

  @doc "Trims fields values in changeset"
  @spec trim(Ecto.Changeset.t(), [atom()] | atom()) :: Ecto.Changeset.t()
  def trim(%Ecto.Changeset{} = changeset, field_or_fields) do
    field_or_fields
    |> List.wrap()
    |> Enum.reduce(changeset, fn field, changeset ->
      Ecto.Changeset.update_change(changeset, field, &String.trim/1)
    end)
  end

  @doc """
  Generates a unique value. Requires at least a generator and a length

  ## Examples

      iex> generate_unique(changeset, :code, generator: Galerie.Generator.Base64, length: 12)

  The above generates a 12 char long base 64 encoded string as ̀`:code`
  """
  @spec generate_unique(Ecto.Changeset.t(), atom(), Keyword.t()) :: Ecto.Changeset.t()
  def generate_unique(%Ecto.Changeset{} = changeset, field, options) do
    {generator, options} = Keyword.pop!(options, :generator)
    value = Galerie.Generator.unique(generator, options)
    Ecto.Changeset.put_change(changeset, field, value)
  end

  @doc "Applies a given function a valid changeset"
  @spec update_valid(Ecto.Changeset.t(), (Ecto.Changeset.t() -> Ecto.Changeset.t())) ::
          Ecto.Changeset.t()
  def update_valid(%Ecto.Changeset{valid?: true} = changeset, function) do
    function.(changeset)
  end

  def update_valid(changeset, _), do: changeset
end
