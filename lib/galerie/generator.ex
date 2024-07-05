defmodule Galerie.Generator do
  @moduledoc """
  Behaviour for generating random values. Generators needs to implement
  this behaviour.
  """
  import Ecto.Query

  alias Galerie.Repo

  @callback generate(Keyword.t()) :: String.t()

  @typedoc "Module implementing the Galerie.Generator behaviour"
  @type generator :: {module(), Keyword.t()}

  @type generate_option ::
          {:max_tries, non_neg_integer()}
          | {:schema, {module(), atom()}}
  @doc """
  Generates a unique value using the provided generator. Option `:schema`
  is required to validate the presence of the value.

  ## Example

      iex> genereate(Alphanumerical, schema: {User, :reset_password_token})

  The above example will validate that the generated value doesn't exist as
  a `:reset_password_token` in the `User` scheme
  """
  @spec unique(generator(), [generate_option() | {atom(), any()}]) :: String.t()
  def unique(generator, options) do
    {schema, field} = Keyword.fetch!(options, :schema)
    max_tries = Keyword.get(options, :max_tries, default_max_tries())

    unique(generator, schema, field, {0, max_tries})
  end

  defp unique(generator, schema, field, {tries, max_tries}) when tries < max_tries do
    value = generate(generator)

    if exists?(schema, field, value) do
      unique(generator, schema, field, {tries + 1, max_tries})
    else
      value
    end
  end

  defp unique(generator, schema, field, {_, max_tries}) do
    raise RuntimeError,
      message:
        "Max tries reached after #{max_tries} attempt to generate using #{inspect(generator)} for #{inspect(schema)}.#{inspect(field)}"
  end

  defp exists?(schema, field, value) do
    schema
    |> where([s], field(s, ^field) == ^value)
    |> Repo.exists?()
  end

  def generate({generator, options}) do
    generate(generator, options)
  end

  def generate(generator, options) do
    generator.generate(options)
  end

  defp default_max_tries,
    do: Application.fetch_env!(:galerie, Galerie.Generator)[:default_max_tries]
end
