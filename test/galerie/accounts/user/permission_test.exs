defmodule Galerie.Accounts.User.PermissionTest do
  use Galerie.BaseCase
  alias Galerie.Accounts.User.Permission, as: UserPermission

  import Bitwise, only: [{:<<<, 2}]

  @permissions UserPermission.permissions()
  @permissions_binaries Enum.with_index(@permissions, &{&1, 0b1 <<< &2})
  @permissions_maximum Enum.reduce(@permissions_binaries, 0, fn {_, binary}, acc ->
                         acc + binary
                       end)

  describe "to_permissions/2" do
    test "creates permissions list from integer" do
      assert Enum.reverse(@permissions) == UserPermission.to_permissions(@permissions_maximum)
    end

    test "returns empty list for integer outside range" do
      assert [] == UserPermission.to_permissions(@permissions_maximum + 1)
    end

    test "permissions list can be converted back as integer" do
      integer = 1

      assert integer ==
               integer
               |> UserPermission.to_permissions()
               |> UserPermission.to_integer()
    end
  end

  describe "to_integer/2" do
    test "converts permissions list to integer discarding invalid permissions" do
      assert 1 == UserPermission.to_integer([:upload_pictures])
      assert 1 == UserPermission.to_integer([:upload_pictures, :something_else])
      assert 0 == UserPermission.to_integer([])
    end
  end
end
