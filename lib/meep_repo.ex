defmodule Meep.Repo do
  use Ecto.Repo,
    otp_app: :meep,
    adapter: Ecto.Adapters.Postgres

  alias Meep.Repo.Page

  require Ecto.Query

  @default_limit 25
  @default_offset 0

  def first(queryable) do
    queryable
    |> with_default_ordering()
    |> Ecto.Query.limit(1)
    |> one()
  end

  def fetch_first(queryable) do
    queryable
    |> with_default_ordering()
    |> first()
    |> to_result()
  end

  def fetch_one(queryable) do
    queryable
    |> with_default_ordering()
    |> one()
    |> to_result()
  end

  def fetch(queryable, id) do
    queryable
    |> get(id)
    |> to_result()
  end

  def fetch_by(queryable, values) do
    queryable
    |> get_by(values)
    |> to_result()
  end

  def get_field(queryable, field) do
    queryable
    |> Ecto.Query.select([q], field(q, ^field))
    |> one()
  end

  def get_field(schema, id, field) do
    schema
    |> Ecto.Query.where([s], s.id == ^id)
    |> get_field(field)
  end

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

  defp to_result(record), do: Result.from_nil(record, :not_found)

  def assoc(%_{} = record, association) do
    if many_association?(record, association) do
      record
      |> Ecto.assoc(association)
      |> all()
    else
      record
      |> Ecto.assoc(association)
      |> one()
    end
  end

  defp many_association?(%struct{}, association) do
    :association
    |> struct.__schema__(association)
    |> many_association?()
  end

  defp many_association?(%{cardinality: cardinality}), do: cardinality != :one

  defp with_default_ordering(queryable) when is_atom(queryable) do
    Ecto.Query.order_by(queryable, :id)
  end

  defp with_default_ordering(%Ecto.Query{order_bys: []} = query) do
    Ecto.Query.order_by(query, :id)
  end

  defp with_default_ordering(query), do: query
end
