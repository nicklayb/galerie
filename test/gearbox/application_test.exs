defmodule Gearbox.ApplicationTest do
  use Nectarine.DataCase
  alias Nectarine.User

  defmodule MockMiddleware do
    @moduledoc "Mock middleware that adds a function into the conext to be used later on"
    @behaviour Gearbox.Middleware

    @impl Gearbox.Middleware
    def run(_, %{abort: reason}) do
      {:abort, reason}
    end

    def run(_, %{function: _}), do: :continue

    def run(_, context) do
      {:continue, Map.put(context, :function, &String.upcase/1)}
    end
  end

  defmodule MockActionHandler do
    @moduledoc """
    Mock action handler that has both cases where:
    - action has handler and after transaction
    - action has handler only
    - action has after transaction only
    """
    @behaviour Gearbox.ActionHandler

    @impl Gearbox.ActionHandler
    def handle(multi, {User, {:create, params}}, %{function: function}) do
      changeset =
        params
        |> Map.update!(:first_name, function)
        |> User.changeset()

      Ecto.Multi.insert(multi, :user, changeset)
    end

    def handle(_, {User, {:reset_password, nil}}, _), do: {:error, :missing_user_id}

    def handle(multi, {User, {:reset_password, user_id}}, _) do
      multi
      |> Ecto.Multi.run(:get_user, fn repo, _ -> repo.fetch(User, user_id) end)
      |> Ecto.Multi.update(:user, &User.reset_password_changeset(&1.get_user))
    end

    def handle(_, _, _), do: :skip

    @impl Gearbox.ActionHandler
    def after_transaction(
          {User, {:create, _params}},
          result,
          %{pid: pid}
        ) do
      send_back(pid, {:after_transaction, result})
    end

    def after_transaction(
          {Project, _action},
          _result,
          %{pid: pid}
        ) do
      send_back(pid, {:after_transaction, :project_created})
    end

    def after_transaction(_, _, %{pid: _}), do: :skip
    def after_transaction(_, _, _), do: {:error, :missing_pid}

    defp send_back(nil, _), do: :ok

    defp send_back(pid, message), do: send(pid, message)
  end

  defmodule MockApplication do
    @behaviour Gearbox.Application

    @impl Gearbox.Application
    def middlewares(_), do: [MockMiddleware]

    @impl Gearbox.Application
    def repo(_), do: Nectarine.Repo

    @impl Gearbox.Application
    def route(User, _), do: MockActionHandler
    def route(Project, _), do: MockActionHandler
    def route(Song, _), do: MockActionHandler

    @impl Gearbox.Application
    def event_handlers(User, _), do: [MockActionHandler]
    def event_handlers(Project, _), do: [MockActionHandler]
  end

  @user_params %{
    email: "paul.blart@mallcop.com",
    first_name: "Paul",
    last_name: "Blart",
    password: "Shawi1234",
    password_confirmation: "Shawi1234"
  }
  describe "dispatch/3" do
    test "dispatches an action, runs the middleware and the after transaction" do
      assert {:ok, %{user: %User{first_name: "PAUL", email: "paul.blart@mallcop.com"}}} =
               Gearbox.Application.dispatch(MockApplication, {User, {:create, @user_params}},
                 context: %{pid: self()}
               )

      assert_receive({:after_transaction, %{user: %User{email: "paul.blart@mallcop.com"}}})
    end

    test "dispatches an action, runs the middleware but simply continues and the after transaction" do
      assert {:ok, %{user: %User{first_name: "paul", email: "paul.blart@mallcop.com"}}} =
               Gearbox.Application.dispatch(MockApplication, {User, {:create, @user_params}},
                 context: %{pid: self(), function: &String.downcase/1}
               )

      assert_receive({:after_transaction, %{user: %User{email: "paul.blart@mallcop.com"}}})
    end

    test "doesn't run after transaction if handle failed" do
      assert {:error, {:user, %Ecto.Changeset{valid?: false}, _}} =
               Gearbox.Application.dispatch(
                 MockApplication,
                 {User, {:create, %{first_name: "Roger"}}},
                 context: %{pid: self()}
               )

      refute_receive({:after_transaction, _})
    end

    test "aborts if middleware returns :abort" do
      assert {:error, {:aborted, MockMiddleware, :whoops}} =
               Gearbox.Application.dispatch(MockApplication, {User, {:create, @user_params}},
                 context: %{pid: self(), abort: :whoops}
               )

      refute_receive({:after_transaction, _})
    end

    test "raises if route doesn't match" do
      assert_raise(FunctionClauseError, fn ->
        Gearbox.Application.dispatch(MockApplication, {Dragon, :fly})
      end)
    end

    test "raises if action handler doesn't match" do
      assert_raise(FunctionClauseError, fn ->
        Gearbox.Application.dispatch(MockApplication, {Song, :play})
      end)
    end

    test "can skip after_transaction even if handle passed" do
      {:ok, %{user: %User{id: user_id, reset_password_token: nil}}} =
        Gearbox.Application.dispatch(MockApplication, {User, {:create, @user_params}},
          context: %{pid: nil}
        )

      assert {:ok, %{user: %User{reset_password_token: reset_password_token}}} =
               Gearbox.Application.dispatch(MockApplication, {User, {:reset_password, user_id}},
                 context: %{pid: self()}
               )

      assert is_binary(reset_password_token)

      refute_receive({:after_transaction, _})
    end

    test "returns error if all handle skipped" do
      assert {:error, :no_operations} ==
               Gearbox.Application.dispatch(MockApplication, {Project, :create},
                 context: %{pid: self()}
               )

      refute_receive({:after_transaction, :project_created})
    end

    test "handlers can return errors" do
      assert {:error, :missing_user_id} =
               Gearbox.Application.dispatch(MockApplication, {User, {:reset_password, nil}})
    end

    test "after_transaction can return errors" do
      assert {:ok, %{user: %User{first_name: "PAUL", email: "paul.blart@mallcop.com"}}} =
               Gearbox.Application.dispatch(MockApplication, {User, {:create, @user_params}})

      refute_receive({:after_transaction, %{user: %User{email: "paul.blart@mallcop.com"}}})
    end
  end
end
