defmodule Nectarine.Middleware.PolicyTest do
  use Nectarine.DataCase

  alias Nectarine.Middleware.Policy

  setup [:create_user]

  describe "run/2 User" do
    test "create user can be run without user", %{user: user} do
      assert {:abort, :already_logged_in} =
               Policy.run(
                 {Nectarine.User, {:create, build(:create_user_params)}},
                 %{user_id: user.id}
               )

      assert :continue =
               Policy.run(
                 {Nectarine.User, {:create, build(:create_user_params)}},
                 %{user_id: nil}
               )
    end

    test "reset password can be run without user", %{user: user} do
      assert {:abort, :already_logged_in} =
               Policy.run(
                 {Nectarine.User, {:reset_password, user}},
                 %{user_id: user.id}
               )

      assert :continue =
               Policy.run(
                 {Nectarine.User, {:reset_password, user}},
                 %{user_id: nil}
               )
    end
  end

  describe "run/2 Project" do
    test "create_project needs a matching user", %{user: user} do
      another_user = insert!(:user)

      assert {:abort, :not_allowed} =
               Policy.run(
                 {Nectarine.Project, {:create, %{owner_id: another_user.id}}},
                 %{user_id: user.id}
               )

      assert :continue =
               Policy.run(
                 {Nectarine.User, {:create, %{owner_id: user.id}}},
                 %{user_id: nil}
               )
    end

    test "create_song needs a matching user", %{user: user} do
      another_user = insert!(:user)

      assert {:abort, :not_allowed} =
               Policy.run(
                 {Nectarine.Project, {:create_song, %{owner_id: another_user.id}}},
                 %{user_id: user.id}
               )

      assert :continue =
               Policy.run(
                 {Nectarine.User, {:create_song, %{owner_id: user.id}}},
                 %{user_id: nil}
               )
    end

    test "create_folder needs a matching user", %{user: user} do
      another_user = insert!(:user)

      assert {:abort, :not_allowed} =
               Policy.run(
                 {Nectarine.Project, {:create_folder, %{owner_id: another_user.id}}},
                 %{user_id: user.id}
               )

      assert :continue =
               Policy.run(
                 {Nectarine.User, {:create_folder, %{owner_id: user.id}}},
                 %{user_id: nil}
               )
    end

    test "star_project needs a matching user", %{user: user} do
      another_user = insert!(:user)

      assert {:abort, :not_allowed} =
               Policy.run(
                 {Nectarine.Project, {:star_project, %{owner_id: another_user.id}}},
                 %{user_id: user.id}
               )

      assert :continue =
               Policy.run(
                 {Nectarine.User, {:star_project, %{owner_id: user.id}}},
                 %{user_id: nil}
               )
    end
  end
end
