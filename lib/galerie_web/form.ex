defmodule GalerieWeb.Form do
  defmacro __using__(options) do
    quote do
      use Ecto.Schema
      import GalerieWeb.Form

      @form_name Keyword.fetch!(unquote(options), :name)
    end
  end

  defmacro defform(do: fields) do
    quote do
      alias __MODULE__

      @primary_key false
      embedded_schema do
        unquote(fields)
      end

      def new(params) do
        params
        |> changeset()
        |> then(&%Ecto.Changeset{&1 | action: :validate})
        |> Phoenix.Component.to_form(as: @form_name)
      end

      def submit(%Ecto.Changeset{} = changeset) do
        Ecto.Changeset.apply_action(changeset, :insert)
      end
    end
  end

  defmacro defform(name, do: fields, after: functions) do
    quote do
      defmodule unquote(name) do
        use Ecto.Schema

        alias __MODULE__

        @primary_key false
        embedded_schema do
          unquote(fields)
        end

        unquote(functions)
      end
    end
  end

  def form_keys(module) do
    module.__schema__(:fields) -- embeds_keys(module)
  end

  def embeds_keys(module) do
    module.__schema__(:embeds)
  end
end
