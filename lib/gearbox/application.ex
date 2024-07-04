defmodule Gearbox.Application do
  require Logger
  @type accumulator :: Ecto.Multi.t()
  @type metadata :: Keyword.t()
  @type namespace :: atom()
  @type event_handler :: {module(), metadata()} | module()
  @type action :: {namespace(), {atom(), any()} | atom()}
  @type application :: module()
  @type middleware :: module()
  @type context :: map()

  @doc "Returns the repo for the transaction"
  @callback repo(metadata()) :: module()

  @doc "Routes an action's namespace to a handler"
  @callback route(namespace(), metadata()) :: event_handler() | [event_handler()]

  @doc "Returns event handlers to be used for a given namespace"
  @callback event_handlers(namespace(), metadata()) :: [event_handler()]

  @doc "Returns all middlewares to be run before action execution"
  @callback middlewares(context()) :: [middleware()]

  @doc """
  Dispatches an action in a given application. The action is 
  initially scoped by it namespace to find the right handler
  then all the event handlers are called with the action and
  the namespace as "after action".

  ## Routed handler vs Event handlers

  A routed handler (returned by `route/2`) runs a `Ecto.Multi`
  operation. If this multi fails the operation is aborted and
  returns early. If it went well, then it's gonna through all
  the Event handlers to fire the `after_transaction/3` callback.
  """
  @spec dispatch(application(), action(), metadata()) :: Result.t(any(), any())
  def dispatch(application, action_call, metadata \\ []) do
    metadata =
      metadata
      |> Keyword.put(:handlers, handlers(application, action_call, metadata))
      |> Keyword.put_new(:context, %{})

    with {:continue, context} <- run_middlewares(application, action_call, metadata),
         {:ok, result} <-
           run_handlers(application, action_call, Keyword.put(metadata, :context, context)) do
      run_after_transaction(result, action_call, metadata)
      {:ok, result}
    else
      {:error, _} = error ->
        Logger.error(
          "[#{inspect(application)}].dispatch error=#{inspect(error)} action=#{inspect(action_call)}"
        )

        error

      {:error, key, inner_error, params} = error ->
        Logger.error(
          "[#{inspect(application)}].dispatch error=#{inspect(error)} action=#{inspect(action_call)}"
        )

        {:error, {key, inner_error, params}}

      {:abort, middleware, term} ->
        {:error, {:aborted, middleware, term}}
    end
  end

  defp run_handlers(%Ecto.Multi{} = multi, action_call, metadata) do
    handlers = Keyword.fetch!(metadata, :handlers)
    context = Keyword.fetch!(metadata, :context)

    Enum.reduce_while(handlers, multi, fn handler, acc ->
      case handler.handle(acc, action_call, context) do
        :skip ->
          {:cont, acc}

        {:error, _} = error ->
          Logger.error(
            "[#{inspect(handler)}].handle error=#{inspect(error)} action=#{inspect(action_call)}"
          )

          {:halt, error}

        %Ecto.Multi{} = multi ->
          Logger.info("#{inspect(handler)} action=#{inspect(action_call)}")
          {:cont, multi}
      end
    end)
  end

  defp run_handlers(application, action_call, metadata) do
    transaction_options = Keyword.get(metadata, :transaction_options, [])

    case run_handlers(Ecto.Multi.new(), action_call, metadata) do
      %Ecto.Multi{operations: [_ | _]} = multi ->
        application.repo(metadata).transaction(multi, transaction_options)

      %Ecto.Multi{operations: []} ->
        {:error, :no_operations}

      error ->
        error
    end
  end

  defp run_after_transaction(result, action_call, metadata) do
    handlers = Keyword.fetch!(metadata, :handlers)
    context = Keyword.fetch!(metadata, :context)

    Enum.each(handlers, fn handler ->
      case handler.after_transaction(action_call, result, context) do
        :skip ->
          :ok

        {:error, _} = error ->
          Logger.error(
            "[#{inspect(handler)}].after_transaction error=#{inspect(error)} action=#{inspect(action_call)}"
          )

        result ->
          Logger.info([
            "#{inspect(handler)}.after_transaction action=#{inspect(action_call)} result=#{inspect(result)}"
          ])
      end
    end)
  end

  defp handlers(application, {namespace, _}, metadata) do
    handlers =
      namespace
      |> application.route(metadata)
      |> List.wrap()

    Enum.uniq(handlers ++ application.event_handlers(namespace, metadata))
  end

  defp run_middlewares(application, action_call, metadata) do
    context = Keyword.fetch!(metadata, :context)

    context
    |> application.middlewares()
    |> Enum.reduce_while({:continue, context}, fn middleware, {:continue, acc} ->
      case middleware.run(action_call, acc) do
        :continue ->
          {:cont, {:continue, acc}}

        {:continue, updated_context} ->
          {:cont, {:continue, updated_context}}

        {:abort, term} ->
          {:halt, {:abort, middleware, term}}
      end
    end)
  end
end
