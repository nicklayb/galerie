defmodule Galerie.Repo.Page do
  defstruct [:results, :query, :has_next_page, :limit, :offset]

  alias Galerie.Repo.Page

  @type t :: %Page{
          results: [any()],
          query: Ecto.Queryable.t(),
          has_next_page: boolean(),
          limit: non_neg_integer(),
          offset: non_neg_integer()
        }

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

  @spec merge(t(), t()) :: t()
  def merge(%Page{results: previous_results}, %Page{results: new_results} = right) do
    %Page{right | results: previous_results ++ new_results}
  end
end
