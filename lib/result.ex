defmodule Result do
  @moduledoc """
  Helper function to deal with :ok/:error tuples
  """

  require Logger

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

  @doc "Apply another result function to a success result"
  @spec and_then(t(any(), any()), (any() -> t(any(), any()))) :: t(any(), any())
  def and_then({:ok, result}, function), do: function.(result)
  def and_then(error, _), do: error

  @doc "Log value using success or error function depending on the result"
  @spec log(t(any(), any()), (any() -> any()), (any() -> any())) :: t(any(), any())
  def log(result, success_function, error_function \\ &Function.identity/1)

  def log({:ok, result}, success_function, _) do
    result
    |> then(success_function)
    |> Logger.info()

    {:ok, result}
  end

  def log({:error, error}, _, error_function) do
    error
    |> then(error_function)
    |> Logger.error()

    {:error, error}
  end

  @doc "Applies a function on success result but without keeping the previous result"
  @spec tap(t(any(), any()), (any() -> any()), (any() -> any())) :: t(any(), any())
  def tap(result, success_function, error_function \\ &Function.identity/1)

  def tap({:ok, result}, success_function, _) do
    success_function.(result)
    {:ok, result}
  end

  def tap({:error, error}, _, error_function) do
    error_function.(error)
    {:error, error}
  end

  @doc "Returns success value if success, fallbacks otherwise"
  @spec with_default(t(any(), any()), any()) :: any()
  def with_default({:ok, result}, _), do: result

  def with_default(_, fallback_function) when is_function(fallback_function, 0),
    do: fallback_function.()

  def with_default(_, fallback), do: fallback

  @doc "Creates a result from a boolean value"
  @spec from_boolean(boolean(), any(), any()) :: t(any(), any())
  def from_boolean(true, success, _), do: succeed(success)
  def from_boolean(false, _, error), do: fail(error)
end
