defmodule Nectarine.User.PasswordTest do
  use Nectarine.BaseCase
  alias Nectarine.User.Password

  setup [:enforce_password_rules]

  describe "validate/2" do
    test "validates a valid password" do
      assert %Ecto.Changeset{errors: []} =
               %{password: "Shawi1234"}
               |> changeset(:password)
               |> Password.validate()
    end

    @tag enforce_rules: false
    test "doesn't enforce if not configured" do
      assert %Ecto.Changeset{errors: []} =
               %{password: "allo"}
               |> changeset(:password)
               |> Password.validate()
    end

    test "adds no error if not changed" do
      assert %Ecto.Changeset{errors: []} =
               %{}
               |> changeset(:password)
               |> Password.validate(:password)
    end

    test "invalidates if less than 8" do
      assert %Ecto.Changeset{errors: [password: {"must be at least 8 characters long", []}]} =
               %{password: "Sha123"}
               |> changeset(:password)
               |> Password.validate(:password)
    end

    test "invalidates if missing numbers" do
      assert %Ecto.Changeset{errors: [password: {"must have numbers", []}]} =
               %{password: "ShawiShawi"}
               |> changeset(:password)
               |> Password.validate(:password)
    end

    test "invalidates if missing uppercase" do
      assert %Ecto.Changeset{errors: [password: {"must have capitals", []}]} =
               %{password: "shawi12341234"}
               |> changeset(:password)
               |> Password.validate(:password)
    end

    test "invalidates if missing lowercase" do
      assert %Ecto.Changeset{errors: [password: {"must have non capitals", []}]} =
               %{password: "SHAWI1234"}
               |> changeset(:password)
               |> Password.validate(:password)
    end
  end

  defp changeset(params, field, data \\ %{}) do
    Ecto.Changeset.cast({data, %{field => :string}}, params, [field])
  end
end
