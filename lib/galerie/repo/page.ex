defmodule Galerie.Repo.Page do
  defstruct [:results, :query, :has_next_page, :limit, :offset]

  alias Galerie.Repo.Page

  def new(results, %Page{query: query, limit: limit, offset: offset}) do
    new(results, query, limit, offset)
  end

  def new(results, query, limit, offset) do
    has_next_page = Enum.count(results) > limit

    %Page{
      results: Enum.take(results, limit),
      query: query,
      has_next_page: has_next_page,
      limit: limit,
      offset: offset
    }
  end
end
