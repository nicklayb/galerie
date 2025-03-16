defmodule Galerie.UseCase do
  alias Galerie.Accounts.User
  alias Galerie.Repo
  require Logger

  defmacro __using__(_) do
    quote do
      use Box.UseCase
    end
  end

  @type use_case :: module()
  @type params :: any()
  @type options :: Keyword.t()

  @spec execute!(use_case(), params(), options()) :: any()
  def execute!(module, params, options \\ []) do
    Box.UseCase.execute!(module, params, with_default_options(options))
  end

  @spec execute(use_case(), params(), options()) :: any()
  def execute(module, params, options \\ []) do
    Box.UseCase.execute(module, params, with_default_options(options))
  end

  defp with_default_options(options) do
    Keyword.put(options, :run, &Repo.transaction/2)
  end

  def can?(use_case_options, permission, options \\ []) do
    case {Keyword.get(use_case_options, :user), Keyword.get(options, :required, true)} do
      {nil, true} ->
        {:error, :unauthorized}

      {nil, false} ->
        {:ok, nil}

      {:system, _} ->
        {:ok, :system}

      {%User{} = user, _} ->
        user
        |> User.can?(permission)
        |> Box.Result.from_boolean(user, :unauthorized)
    end
  end
end
