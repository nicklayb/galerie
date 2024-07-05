defmodule Galerie.Repo do
  use Ecto.Repo,
    otp_app: :galerie,
    adapter: Ecto.Adapters.Postgres

  require Ecto.Query

  @type record_id :: integer()

  def first(queryable) do
    queryable
    |> Ecto.Query.limit(1)
    |> all()
    |> List.first()
  end

  def fetch_first(queryable) do
    queryable
    |> first()
    |> to_result()
  end

  def fetch_by(schema, keys) do
    schema
    |> get_by(keys)
    |> to_result()
  end

  def fetch(schema, id) do
    schema
    |> get(id)
    |> to_result()
  end

  def fetch_one(queryable) do
    queryable
    |> one()
    |> to_result()
  end

  @default_limit 25
  @default_offset 0
  def paginate(queryable, params \\ %{}) do
    limit = Map.get(params, :limit, @default_limit)
    offset = Map.get(params, :offset, @default_offset)
    sort_by = Map.get(params, :sort_by, :id)

    queryable
    |> Ecto.Query.subquery()
    |> Ecto.Query.order_by(^sort_by)
    |> Ecto.Query.limit(^(limit + 1))
    |> Ecto.Query.offset(^offset)
    |> all()
    |> Page.new(queryable, limit, offset)
  end

  def next(%Page{query: query, limit: limit, offset: offset}) do
    paginate(query, %{offset: offset + limit, limit: limit})
  end

  def map_paginated_results(%Page{results: results} = page, function) do
    %Page{page | results: function.(results)}
  end

  defp to_result(record_or_nil), do: Result.from_nil(record_or_nil, :not_found)

  def unwrap_transaction({:ok, result}, key), do: {:ok, Map.get(result, key)}

  def unwrap_transaction(result, _), do: result
end
