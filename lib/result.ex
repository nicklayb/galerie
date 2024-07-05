defmodule Result do
  @moduledoc """
  Helper function to deal with :ok/:error tuples
  """

  @type success(success_type) :: {:ok, success_type}
  @type error(error_type) :: {:error, error_type} | :error
  @type t(success_type, error_type) :: success(success_type) | error(error_type)

  @doc """
  Returns {:ok, value} if the value is not nil, returns
  an error tuple if the given value is nil with error
  as second value
  """
  @spec from_nil(any(), any()) :: t(any(), any())
  def from_nil(value, error \\ nil)
  def from_nil(nil, error), do: fail(error)
  def from_nil(record, _), do: succeed(record)

  @doc "Returns an ok tuple"
  @spec succeed(any()) :: t(any(), any())
  def succeed(record), do: {:ok, record}

  @doc "Returns an error tuple"
  @spec fail(any()) :: t(any(), any())
  def fail(nil), do: :error
  def fail(error), do: {:error, error}

  @doc "Returns true if the result is an ok tuple"
  @spec succeeded?(t(any(), any())) :: boolean()
  def succeeded?({:ok, _}), do: true
  def succeeded?(_), do: false

  @doc "Extracts the value from a success tuple"
  @spec unwrap!(t(any(), any())) :: any()
  def unwrap!({:ok, result}), do: result

  @doc "Maps a success value"
  @spec map(t(any(), any()), (any() -> any())) :: t(any(), any())
  def map({:ok, result}, function), do: {:ok, function.(result)}
  def map(error, _), do: error

  @spec tap(t(any(), any()), (any() -> any())) :: t(any(), any())
  def tap({:ok, result}, function) do
    function.(result)
    {:ok, result}
  end

  def tap(error, _), do: error

  def with_default({:ok, result}, _), do: result
  def with_default(_, fallback), do: fallback
end
