defmodule Galerie.RepoTest do
  use Galerie.DataCase
  alias Galerie.Accounts.User
  alias Galerie.Repo

  describe "first/1" do
    test "gets first record in db" do
      %User{id: user_id} = insert!(:user)
      assert %User{id: ^user_id} = Repo.first(User)
    end

    test "return nil if record in db" do
      assert nil == Repo.first(User)
    end
  end

  describe "fetch_first/1" do
    test "fetches first record in db" do
      %User{id: user_id} = insert!(:user)
      assert {:ok, %User{id: ^user_id}} = Repo.fetch_first(User)
    end

    test "errors if no record in db" do
      assert {:error, :not_found} = Repo.fetch_first(User)
    end
  end

  describe "fetch_by/2" do
    test "fetches by fields" do
      %User{id: user_id} = user = insert!(:user)
      assert {:ok, %User{id: ^user_id}} = Repo.fetch_by(User, email: user.email)
    end

    test "returns error if no record" do
      assert {:error, :not_found} = Repo.fetch_by(User, email: "email")
    end
  end

  describe "fetch/2" do
    test "fetches by id" do
      %User{id: user_id} = insert!(:user)
      assert {:ok, %User{id: ^user_id}} = Repo.fetch(User, user_id)
    end

    test "returns error if no record" do
      assert {:error, :not_found} = Repo.fetch(User, Ecto.UUID.generate())
    end
  end

  describe "fetch_one/1" do
    test "fetches one record" do
      %User{id: user_id} = insert!(:user)
      assert {:ok, %User{id: ^user_id}} = Repo.fetch_one(User)
    end

    test "errors if no record" do
      assert {:error, :not_found} = Repo.fetch_one(User)
    end
  end

  describe "unwrap_transaction/2" do
    test "unwraps transaction by key if succeeds" do
      params = %{
        first_name: "John",
        last_name: "Doe",
        email: "john.doe@email.com",
        password: "Shawi1234",
        password_confirmation: "Shawi1234"
      }

      multi = Ecto.Multi.insert(Ecto.Multi.new(), :user, User.changeset(params))
      assert {:ok, %{user: %User{}}} = transaction_result = Repo.transaction(multi)
      assert {:ok, %User{}} = Repo.unwrap_transaction(transaction_result, :user)
    end

    test "returns same error tuple if failing" do
      multi = Ecto.Multi.insert(Ecto.Multi.new(), :user, User.changeset(%{}))

      assert {:error, :user, %Ecto.Changeset{valid?: false}, %{}} =
               transaction_result = Repo.transaction(multi)

      assert {:error, :user, %Ecto.Changeset{valid?: false}, %{}} =
               Repo.unwrap_transaction(transaction_result, :user)
    end
  end
end
