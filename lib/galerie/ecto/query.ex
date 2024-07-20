defmodule Galerie.Ecto.Query do
  def join_once(query, named_binding, function) do
    if Ecto.Query.has_named_binding?(query, named_binding) do
      query
    else
      function.(query)
    end
  end
end
