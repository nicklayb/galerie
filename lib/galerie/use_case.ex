defmodule Galerie.UseCase do
  alias Galerie.Repo
  @type params :: any()
  @callback validate(params(), Keyword.t()) :: {:ok, params()} | :ignore | {:error, any()}
  @callback run(Ecto.Multi.t(), params(), Keyword.t()) :: Ecto.Mutli.t()
  @callback after_run(params(), Keyword.t()) :: any()
  @callback return(params(), Keyword.t()) :: any()

  defmacro __using__(_) do
    quote do
      @behaviour Galerie.UseCase

      def execute!(params, options \\ []) do
        Galerie.UseCase.execute!(__MODULE__, params, options)
      end

      def execute(params, options \\ []) do
        Galerie.UseCase.execute(__MODULE__, params, options)
      end

      def validate(map, _), do: {:ok, map}

      def after_run(_map, _), do: :ok

      def return(map, _), do: map

      defoverridable(validate: 2, after_run: 2, return: 2)
    end
  end

  def execute(module, params, options) do
    transaction_options = Keyword.get(options, :transaction, [])

    with {:ok, new_params} <- module.validate(params, options),
         {:ok, %Ecto.Multi{} = multi} <- build_multi(module, new_params, options),
         {:ok, result} <- Repo.transaction(multi, transaction_options) do
      options = Keyword.put(options, :params, params)

      if Keyword.get(options, :after_run?, true) do
        module.after_run(result, options)
      end

      {:ok, module.return(result, options)}
    end
  end

  def execute!(module, params, options) do
    case execute(module, params, options) do
      {:ok, result} ->
        result

      :ignore ->
        :ignore

      {:error, _} = error ->
        raise "Usecase #{module} execution failed with #{inspect(error)}"

      {:error, _, _} = error ->
        raise "Usecase #{module} execution failed with #{inspect(error)}"
    end
  end

  defp build_multi(module, params, options) do
    case module.run(Ecto.Multi.new(), params, options) do
      %Ecto.Multi{} = multi ->
        {:ok, multi}

      other ->
        raise "Expected UseCase #{inspect(module)} to return Ecto.Multi.t(), got: #{inspect(other)}"
    end
  end
end
