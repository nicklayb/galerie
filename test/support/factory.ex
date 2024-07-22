defmodule GalerieTest.Support.Factory do
  alias Galerie.Repo

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

    %Galerie.Accounts.User{
      id: id(),
      first_name: "John",
      last_name: "Doe",
      email: "john.doe.#{id}@email.com",
      password: "some password hash",
      inserted_at: now(),
      updated_at: now()
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
