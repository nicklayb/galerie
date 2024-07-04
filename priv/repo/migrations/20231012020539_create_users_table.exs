defmodule Nectarine.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create(table("users")) do
      add(:email, :string, null: false)
      add(:first_name, :string)
      add(:last_name, :string)
      add(:password, :string, null: false)
      add(:reset_password_token, :string)

      timestamps()
    end

    create(unique_index("users", [:email]))
  end
end
