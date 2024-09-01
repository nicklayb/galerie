defmodule Galerie.Ecto.Query do
  @moduledoc """
  Ecto query helper functions.
  """

  @doc """
  Applies a function only if the given binding is not already bound.

  The given `join_function/1` function is likely expected to be a `join/5`
  call in order to join the previous binding.
  """
  @type join_function :: (Ecto.Queryable.t() -> Ecto.Query.t())
  @spec join_once(Ecto.Queryable.t(), atom(), join_function()) :: Ecto.Query.t()
  def join_once(query, named_binding, function) do
    if Ecto.Query.has_named_binding?(query, named_binding) do
      query
    else
      function.(query)
    end
  end
end
