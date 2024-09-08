defmodule Galerie.Form do
  defmacro __using__(options) do
    quote do
      use Ecto.Schema
      import Galerie.Form

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

      def new(%Ecto.Changeset{} = changeset) do
        changeset
        |> then(&%Ecto.Changeset{&1 | action: :validate})
        |> Phoenix.Component.to_form(as: @form_name)
      end

      def new(params) do
        params
        |> changeset()
        |> new()
      end

      def submit(%Ecto.Changeset{} = changeset) do
        changeset
        |> Ecto.Changeset.apply_action(:insert)
        |> Result.map(&post_submit/1)
      end

      def submit(%{} = params) do
        params
        |> new()
        |> Map.fetch!(:source)
        |> submit()
      end

      def post_submit(form), do: form

      defoverridable(post_submit: 1)
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
