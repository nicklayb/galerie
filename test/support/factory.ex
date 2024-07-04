defmodule NectarineTest.Support.Factory do
  alias Nectarine.Repo

  def insert!(type, params \\ []) do
    type
    |> build(params)
    |> Repo.insert!()
  end

  def build(type, params) do
    type
    |> build()
    |> struct!(params)
  end

  def build(:user) do
    id = next_integer(:user_id)

    %Nectarine.User{
      id: id(),
      first_name: "John",
      last_name: "Doe",
      email: "john.doe.#{id}@email.com",
      password: "some password hash",
      inserted_at: now(),
      updated_at: now()
    }
  end

  def build(:create_user_params) do
    id = next_integer(:user_id)

    %{
      first_name: "Jane",
      last_name: "Doe",
      email: "jane.doe.#{id}@email.com",
      password: "Shawi1234",
      password_confirmation: "Shawi1234"
    }
  end

  defp id, do: Ecto.UUID.generate()

  defp next_integer(namespace) do
    namespace
    |> Process.get(0)
    |> then(&(&1 + 1))
    |> tap(&Process.put(namespace, &1))
  end

  defp now, do: NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
end
