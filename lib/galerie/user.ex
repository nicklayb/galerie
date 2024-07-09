defmodule Galerie.User do
  use Ecto.Schema
  alias Galerie.Folder
  alias Galerie.User
  alias Galerie.User.Password

  require Logger

  @type t :: %User{}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema("users") do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:password, :string)
    field(:password_confirmation, :string, virtual: true)
    field(:reset_password_token, :string)

    field(:permissions, Galerie.Ecto.Types.Permissions)
    field(:is_admin, :boolean)

    belongs_to(:folder, Folder)

    timestamps()
  end

  @required ~w(first_name last_name email password password_confirmation)a
  @optional ~w(is_admin permissions)a
  @castable @required ++ @optional
  @trimable ~w(first_name last_name email)a
  def changeset(%User{} = user \\ %User{}, params) do
    user
    |> Ecto.Changeset.cast(params, @castable)
    |> Galerie.Ecto.Changeset.trim(@trimable)
    |> Ecto.Changeset.update_change(:email, &String.downcase/1)
    |> Ecto.Changeset.validate_format(:email, ~r/(.+)@(.+)\.(.+)/)
    |> Ecto.Changeset.validate_required(@required)
    |> Ecto.Changeset.unique_constraint(:email)
    |> Password.validate()
    |> Ecto.Changeset.validate_confirmation(:password)
    |> Galerie.Ecto.Changeset.hash(:password)
  end

  @required ~w(password password_confirmation)a
  def update_password_changeset(%User{} = user, params) do
    user
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
    |> Password.validate()
    |> Ecto.Changeset.validate_confirmation(:password)
    |> Galerie.Ecto.Changeset.hash(:password)
    |> Ecto.Changeset.put_change(:reset_password_token, nil)
  end

  @reset_password_token_length 32
  def reset_password_changeset(%User{} = user) do
    user
    |> Ecto.Changeset.cast(%{}, [])
    |> Galerie.Ecto.Changeset.generate_unique(:reset_password_token,
      generator: {Galerie.Generator.Base64, length: @reset_password_token_length},
      schema: {User, :reset_password_token}
    )
  end

  @doc "Gets user's fullname"
  @spec fullname(t()) :: String.t()
  def fullname(%User{first_name: first_name, last_name: last_name}),
    do: "#{first_name} #{last_name}"

  @doc "Gets user's initials"
  def initials(%User{first_name: first_name, last_name: last_name}),
    do: "#{String.first(first_name)}#{String.first(last_name)}"

  def can?(%User{is_admin: true}, _), do: true
  def can?(%User{permissions: permissions}, permission), do: permission in permissions
end

defimpl Swoosh.Email.Recipient, for: Galerie.User do
  def format(%Galerie.User{email: email} = user) do
    {Galerie.User.fullname(user), email}
  end
end
