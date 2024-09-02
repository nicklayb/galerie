defmodule Galerie.Accounts.User do
  @moduledoc """
  The User schema represents an actual user in the system for either
  admin or normal user. Only benefit of admin users is to bypass the
  permissions checks.

  Users are also expected to have a dedicated Folder created for 
  manually uploaded pictures from the web UI.
  """
  use Galerie, :schema
  alias Galerie.Accounts.Permission
  alias Galerie.Accounts.User
  alias Galerie.Accounts.User.Password
  alias Galerie.Accounts.User.Permission, as: UserPermission
  alias Galerie.Folders.Folder

  require Logger

  @derive {Inspect, only: [:email]}
  schema("users") do
    field(:email, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:password, :string)
    field(:password_confirmation, :string, virtual: true)
    field(:reset_password_token, :string)

    field(:permissions, Galerie.Ecto.Types.Permissions,
      module: UserPermission,
      default: []
    )

    field(:is_admin, :boolean)

    has_one(:folder, Folder)

    timestamps()
  end

  @required ~w(first_name last_name email password password_confirmation)a
  @optional ~w(is_admin permissions)a
  @castable @required ++ @optional
  @trimable ~w(first_name last_name email)a
  @doc """
  User's basic changeset used for creation and update from an admin perspective,
  standard users *should* not be able to use this changeset on existing structure.
  """
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
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
  @doc """
  Changeset to update a user's password and validate they are respecting the
  password requirements.
  """
  @spec update_password_changeset(t(), map()) :: Ecto.Changeset.t()
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
  @doc """
  Changeset to initiate a password reset, it takes no parameters as it
  just sets a reset password token.
  """
  @spec reset_password_changeset(t()) :: Ecto.Changeset.t()
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
  @spec initials(t()) :: String.t()
  def initials(%User{first_name: first_name, last_name: last_name}),
    do: "#{String.first(first_name)}#{String.first(last_name)}"

  @spec can?(t(), UserPermission.t()) :: boolean()
  def can?(%User{is_admin: true}, _), do: true
  def can?(%User{permissions: permissions}, permission), do: permission in permissions
end

defimpl Swoosh.Email.Recipient, for: Galerie.Accounts.User do
  def format(%Galerie.Accounts.User{email: email} = user) do
    {Galerie.Accounts.User.fullname(user), email}
  end
end
