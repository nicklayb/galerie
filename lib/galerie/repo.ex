defmodule Galerie.Repo do
  use Ecto.Repo,
    otp_app: :galerie,
    adapter: Ecto.Adapters.Postgres

  alias Galerie.Repo.Page
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
    |> order_paginated_query(sort_by)
    |> Ecto.Query.limit(^(limit + 1))
    |> Ecto.Query.offset(^offset)
    |> all()
    |> Page.new(queryable, limit, offset, sort_by)
  end

  defp order_paginated_query(query, order_by) when is_function(order_by, 1) do
    order_by.(query)
  end

  defp order_paginated_query(query, order_by) do
    Ecto.Query.order_by(query, ^order_by)
  end

  def next(%Page{query: query, limit: limit, offset: offset, sort_by: sort_by}) do
    paginate(query, %{offset: offset + limit, limit: limit, sort_by: sort_by})
  end

  def map_paginated_results(%Page{results: results} = page, function) do
    %Page{page | results: function.(results)}
  end

  defp to_result(record_or_nil), do: Result.from_nil(record_or_nil, :not_found)

  def unwrap_transaction({:ok, result}, key), do: {:ok, Map.get(result, key)}

  def unwrap_transaction(result, _), do: result

  def reload_assoc(%struct{} = schema, assoc_or_assocs) do
    new_struct = struct!(struct, [])
    assocs = List.wrap(assoc_or_assocs)

    assocs
    |> Enum.reduce(schema, fn assoc, schema ->
      unloaded = Map.fetch!(new_struct, assoc)

      Map.put(schema, assoc, unloaded)
    end)
    |> preload(assocs)
  end

  def touch(%_{} = schema) do
    schema
    |> Ecto.Changeset.cast(%{}, [])
    |> update(force: true)
  end

  def touch_changeset(%_{} = schema) do
    Ecto.Changeset.cast(schema, %{}, [])
  end
end
