defmodule Galerie.Ecto.ChangesetTest do
  use Galerie.DataCase
  alias Galerie.Ecto.Changeset
  alias GalerieTest.Support.Mocks.MockGenerator

  describe "touch_timestamp/1" do
    test "updates timestamp if setter is true" do
      assert %Ecto.Changeset{changes: %{merged: true}} =
               changeset =
               Ecto.Changeset.cast(
                 {%{}, %{merged: :boolean, merged_at: :utc_datetime}},
                 %{merged: true},
                 [:merged]
               )

      assert %Ecto.Changeset{errors: [], changes: %{merged_at: %DateTime{}}} =
               Changeset.touch_timestamp(changeset, setter: :merged)
    end

    test "set timestamp nil if setter is false" do
      assert %Ecto.Changeset{changes: %{merged: false}} =
               changeset =
               Ecto.Changeset.cast(
                 {%{merged_at: DateTime.utc_now()},
                  %{merged: :boolean, merged_at: :utc_datetime}},
                 %{merged: false},
                 [:merged]
               )

      assert %Ecto.Changeset{errors: [], changes: %{merged_at: nil}} =
               Changeset.touch_timestamp(changeset, setter: :merged)
    end

    test "do not touch timestamp if setter unchanged" do
      assert %Ecto.Changeset{changes: changes} =
               changeset =
               Ecto.Changeset.cast(
                 {%{merged_at: DateTime.utc_now()},
                  %{merged: :boolean, merged_at: :utc_datetime}},
                 %{},
                 [:merged]
               )

      assert changes == %{}

      assert %Ecto.Changeset{errors: [], changes: changes} =
               Changeset.touch_timestamp(changeset, setter: :merged)

      assert changes == %{}
    end

    test "support providing timestamp field" do
      assert %Ecto.Changeset{changes: %{has_been_merged: true}} =
               changeset =
               Ecto.Changeset.cast(
                 {%{}, %{has_been_merged: :boolean, merged_at: :utc_datetime}},
                 %{has_been_merged: true},
                 [:has_been_merged]
               )

      assert %Ecto.Changeset{errors: [], changes: %{merged_at: %DateTime{}}} =
               Changeset.touch_timestamp(changeset, setter: :has_been_merged, key: :merged_at)
    end
  end

  describe "hash/2" do
    test "hashes field" do
      secret_value = "Secret"

      assert %Ecto.Changeset{changes: %{secret: secret_value}} =
               changeset =
               Ecto.Changeset.cast({%{}, %{secret: :string}}, %{secret: secret_value}, [:secret])

      assert %Ecto.Changeset{changes: %{secret: hashed_secret}} =
               Changeset.hash(changeset, :secret)

      assert hashed_secret != secret_value
      assert "$argon2" <> _ = hashed_secret
    end

    test "doesn't hash if invalid" do
      secret_value = "Secret"

      assert %Ecto.Changeset{changes: %{secret: secret_value}} =
               changeset =
               Ecto.Changeset.cast({%{}, %{secret: :string}}, %{secret: secret_value}, [:secret])

      assert %Ecto.Changeset{errors: [{:secret, _}]} =
               changeset = Ecto.Changeset.add_error(changeset, :secret, "invalid")

      assert %Ecto.Changeset{changes: %{secret: ^secret_value}} =
               Changeset.hash(changeset, :secret)
    end
  end

  describe "trim/2" do
    test "trim fields" do
      assert %Ecto.Changeset{changes: %{first_name: "  first  ", last_name: "  last  "}} =
               changeset =
               Ecto.Changeset.cast(
                 {%{}, %{first_name: :string, last_name: :string}},
                 %{first_name: "  first  ", last_name: "  last  "},
                 [:first_name, :last_name]
               )

      assert %Ecto.Changeset{changes: %{first_name: "  first  ", last_name: "last"}} =
               Changeset.trim(changeset, :last_name)

      assert %Ecto.Changeset{changes: %{first_name: "  first  ", last_name: "last"}} =
               Changeset.trim(changeset, [:last_name])

      assert %Ecto.Changeset{changes: %{first_name: "first", last_name: "last"}} =
               Changeset.trim(changeset, [:first_name, :last_name])
    end
  end

  describe "update_valid/2" do
    test "updates only if changeset if valid" do
      assert %Ecto.Changeset{valid?: true} =
               changeset = Ecto.Changeset.cast({%{}, %{name: :string}}, %{name: "Bob"}, [:name])

      assert %Ecto.Changeset{valid?: true, changes: %{name: "BOB"}} =
               changeset =
               Changeset.update_valid(changeset, fn changeset ->
                 Ecto.Changeset.update_change(changeset, :name, &String.upcase/1)
               end)

      assert %Ecto.Changeset{valid?: false} =
               changeset = Ecto.Changeset.add_error(changeset, :name, "invalid")

      assert %Ecto.Changeset{valid?: false, changes: %{name: "BOB"}} =
               Changeset.update_valid(changeset, fn changeset ->
                 Ecto.Changeset.update_change(changeset, :name, &String.downcase/1)
               end)
    end
  end

  describe "format_errors/1" do
    test "format error message" do
      assert %Ecto.Changeset{errors: [{_field_name, inner_error} = error]} =
               {%{}, %{name: :string}}
               |> Ecto.Changeset.cast(%{name: "Bob"}, [:name])
               |> Ecto.Changeset.add_error(:name, "is invalid")

      assert "is invalid" = Changeset.format_error(inner_error)
      assert "is invalid" = Changeset.format_error(error)
    end

    test "format error with count" do
      assert %Ecto.Changeset{errors: [{_field_name, {_, error_options} = inner_error} = error]} =
               {%{}, %{name: :string}}
               |> Ecto.Changeset.cast(%{name: "bob"}, [:name])
               |> Ecto.Changeset.validate_length(:name, min: 5)

      assert Keyword.has_key?(error_options, :count)

      assert "should be at least 5 character(s)" = Changeset.format_error(inner_error)
      assert "should be at least 5 character(s)" = Changeset.format_error(error)
    end
  end

  describe "generate_unique/3" do
    test "generate unique value in schema" do
      changeset = Ecto.Changeset.cast({%{}, %{uuid: :string}}, %{}, [:uuid])
      uuid = Ecto.UUID.generate()

      assert %Ecto.Changeset{changes: %{uuid: ^uuid}} =
               Changeset.generate_unique(changeset, :uuid,
                 generator: {MockGenerator, value: uuid},
                 schema: {Galerie.User, :email}
               )
    end
  end
end
