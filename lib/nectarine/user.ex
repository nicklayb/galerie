defmodule Nectarine.User do
  use Ecto.Schema
  alias Nectarine.ProjectUser
  alias Nectarine.User
  alias Nectarine.User.Password

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

    has_many(:project_users, ProjectUser)
    has_many(:projects, through: [:project_users, :project])

    timestamps()
  end

  @required ~w(first_name last_name email password password_confirmation)a
  @optional ~w()a
  @castable @required ++ @optional
  @trimable ~w(first_name last_name email)a
  def changeset(%User{} = user \\ %User{}, params) do
    user
    |> Ecto.Changeset.cast(params, @castable)
    |> Nectarine.Changeset.trim(@trimable)
    |> Ecto.Changeset.update_change(:email, &String.downcase/1)
    |> Ecto.Changeset.validate_format(:email, ~r/(.+)@(.+)\.(.+)/)
    |> Ecto.Changeset.validate_required(@required)
    |> Ecto.Changeset.unique_constraint(:email)
    |> Password.validate()
    |> Ecto.Changeset.validate_confirmation(:password)
    |> Nectarine.Changeset.hash(:password)
  end

  @required ~w(password password_confirmation)a
  def update_password_changeset(%User{} = user, params) do
    user
    |> Ecto.Changeset.cast(params, @required)
    |> Ecto.Changeset.validate_required(@required)
    |> Password.validate()
    |> Ecto.Changeset.validate_confirmation(:password)
    |> Nectarine.Changeset.hash(:password)
    |> Ecto.Changeset.put_change(:reset_password_token, nil)
  end

  @reset_password_token_length 32
  def reset_password_changeset(%User{} = user) do
    user
    |> Ecto.Changeset.cast(%{}, [])
    |> Nectarine.Changeset.generate_unique(:reset_password_token,
      generator: {Nectarine.Generator.Base64, length: @reset_password_token_length},
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
end

defimpl Swoosh.Email.Recipient, for: Nectarine.User do
  def format(%Nectarine.User{email: email} = user) do
    {Nectarine.User.fullname(user), email}
  end
end
