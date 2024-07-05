defmodule Galerie.UserTest do
  use Galerie.DataCase

  alias Galerie.User

  setup [:initialize_changeset]

  describe "changeset/2" do
    @tag changeset_params: %{
           first_name: " First",
           last_name: "Last ",
           email: "Salut@email.com",
           password: "Shawi1234",
           password_confirmation: "Shawi1234"
         }
    test "applies changeset", %{changeset_params: params} do
      assert %Ecto.Changeset{
               valid?: true,
               errors: [],
               changes: %{
                 first_name: "First",
                 last_name: "Last",
                 email: "salut@email.com",
                 password: "$argon2" <> _,
                 password_confirmation: "Shawi1234"
               }
             } = User.changeset(params)

      assert %Ecto.Changeset{
               valid?: true,
               errors: [],
               changes: %{
                 first_name: "First",
                 last_name: "Last",
                 email: "salut@email.com",
                 password: "$argon2" <> _,
                 password_confirmation: "Shawi1234"
               }
             } = User.changeset(%User{}, params)
    end

    @tag changeset_params: %{
           first_name: nil,
           last_name: nil,
           email: nil,
           password: nil,
           password_confirmation: nil
         }
    test "adds error for missing fields", %{changeset: changeset} do
      assert %Ecto.Changeset{valid?: false, errors: errors} = changeset
      assert {"can't be blank", _} = Keyword.get(errors, :first_name)
      assert {"can't be blank", _} = Keyword.get(errors, :last_name)
      assert {"can't be blank", _} = Keyword.get(errors, :email)
      assert {"can't be blank", _} = Keyword.get(errors, :password)
      assert {"can't be blank", _} = Keyword.get(errors, :password_confirmation)
    end

    @tag changeset_params: %{email: "this is not an email"}
    test "requires email format", %{changeset: changeset} do
      assert %Ecto.Changeset{valid?: false, errors: [{:email, {"has invalid format", _}}]} =
               changeset
    end

    test "email must be unique", %{changeset_params: %{email: email} = params} do
      insert!(:user, email: email)

      assert {:error,
              %Ecto.Changeset{valid?: false, errors: [{:email, {"has already been taken", _}}]}} =
               %User{}
               |> User.changeset(params)
               |> Repo.insert()
    end

    @tag changeset_params: %{password: "Shawi1234", password_confirmation: "1234Shawi"}
    test "password must be identical", %{changeset: changeset} do
      assert %Ecto.Changeset{
               valid?: false,
               errors: [
                 {:password_confirmation,
                  {"does not match confirmation", [validation: :confirmation]}}
               ]
             } = changeset
    end
  end

  describe "update_password_changeset/2" do
    @tag function: :update_password_changeset
    test "hash passwords", %{changeset: changeset, changeset_params: changeset_params} do
      assert %Ecto.Changeset{
               valid?: true,
               changes: %{password: "$argon2" <> _}
             } = changeset

      assert %Ecto.Changeset{
               valid?: true,
               changes: %{password: "$argon2" <> _}
             } = User.update_password_changeset(%User{}, changeset_params)
    end

    @tag changeset_params: %{password: "Shawi1234", password_confirmation: "1234Shawi"},
         function: :update_password_changeset
    test "requires same password", %{changeset: changeset} do
      assert %Ecto.Changeset{
               valid?: false,
               errors: [
                 {:password_confirmation,
                  {"does not match confirmation", [validation: :confirmation]}}
               ]
             } = changeset
    end
  end

  describe "reset_password_changeset/1" do
    @tag function: :reset_password_changeset
    test "sets unique reset password token", %{changeset: changeset} do
      assert %Ecto.Changeset{changes: %{reset_password_token: token}} = changeset
      assert is_binary(token)
    end
  end

  describe "initials/1" do
    test "gets user initials" do
      user = insert!(:user)
      assert "JD" == User.initials(user)
    end
  end

  describe "fullname/1" do
    test "gets user full name" do
      user = insert!(:user)
      assert "John Doe" == User.fullname(user)
    end
  end

  @default_params %{
    first_name: "John",
    last_name: "Doe",
    email: "john.doe@email.com",
    password: "Shawi1234",
    password_confirmation: "Shawi1234"
  }
  defp initialize_changeset(context) do
    params = Map.merge(@default_params, Map.get(context, :changeset_params, %{}))

    changeset =
      case Map.get(context, :function, :changeset) do
        :reset_password_changeset -> User.reset_password_changeset(%User{})
        other -> apply(User, other, [%User{}, params])
      end

    [changeset: changeset, changeset_params: params]
  end
end
