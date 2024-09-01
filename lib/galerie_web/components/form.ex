defmodule GalerieWeb.Components.Form do
  use Phoenix.Component
  alias GalerieWeb.Html

  attr(:name, :atom, required: true)
  attr(:multiple, :boolean, default: false)
  attr(:errors, :list, default: [])
  attr(:class, :string, default: "")
  slot(:inner_block, required: true)
  slot(:label, required: false)

  def element(assigns) do
    name = multiple_name(assigns)
    assigns = assign(assigns, :name, name)

    ~H"""
    <div class={Html.class("group", [{Enum.any?(@errors), "has-errors"}, {@class != "", @class, "flex flex-col gap-y-1 mb-3"}])}>
      <%= if @label do %>
        <label for={@name} class="text-sm pl-0.5 group-[.has-errors]:text-red-400">
          <%= render_slot(@label) %>
        </label>
      <% end %>
      <%= render_slot(@inner_block) %>
      <.field_errors errors={@errors} />
    </div>
    """
  end

  attr(:field, :any, required: true)
  attr(:value, :any, required: true)
  attr(:element_class, :string, default: "")
  attr(:multiple, :boolean, default: false)
  attr(:checked, :boolean, required: true)
  slot(:label, required: false)

  def checkbox(assigns) do
    name = multiple_name(assigns)
    assigns = assign(assigns, :name, name)

    ~H"""
    <.element name={@field.name} errors={@field.errors} class={@element_class} multiple={@multiple}>
      <:label>
        <%= render_slot(@label) %>
      </:label>
      <input type="checkbox" id={@field.id} name={@name} value={@value} checked={@checked}/>
    </.element>
    """
  end

  def hidden(assigns) do
    name = multiple_name(assigns)
    assigns = assign(assigns, :name, name)

    ~H"""
    <input type="hidden" id={@field.id} name={@name} value={@value} />
    """
  end

  defp multiple_name(%{multiple: true, field: field}), do: field.name <> "[]"
  defp multiple_name(%{multiple: true, name: name}), do: name <> "[]"
  defp multiple_name(%{field: field}), do: field.name
  defp multiple_name(%{name: name}), do: name

  attr(:form, :any, default: nil)
  attr(:class, :string, default: "py-1.5 pr-20")
  attr(:element_class, :string, default: "")
  attr(:name, :atom)
  attr(:field, :any)
  attr(:autocomplete, :string, default: "")
  attr(:disabled, :boolean, default: false)
  attr(:rest, :global)

  slot(:label, required: false)

  @class "block w-full bg-true-gray-100 rounded border-0 text-true-gray-900 ring-1 ring-inset ring-true-gray-500 placeholder:text-true-gray-400 focus:ring-2 focus:ring-inset focus:ring-pink-600 sm:text-sm sm:leading-6 group-[.has-errors]:ring-red-400 disabled:bg-true-gray-150 disabled:border-true-gray-300 text-true-gray-500"
  def text_input(%{field: _field} = assigns) do
    assigns = update(assigns, :class, &Html.class(@class, &1))

    ~H"""
    <.element name={@field.name} errors={@field.errors} class={@element_class}>
      <:label>
        <%= render_slot(@label) %>
      </:label>
      <input type="text" id={@field.id} name={@field.name} value={@field.value} class={@class} disabled={@disabled} autocomplete={@autocomplete} onkeyup="event.preventDefault()" {@rest} />
    </.element>
    """
  end

  def text_input(%{rest: rest, class: class, form: form, name: name} = assigns) do
    classes = Html.class(@class, class)

    errors =
      form
      |> Map.get(:errors, [])
      |> Enum.filter(fn {key, _} -> key == name end)
      |> Keyword.values()

    assigns =
      rest
      |> Enum.into([])
      |> Keyword.put(:class, classes)
      |> then(&assign(assigns, :attributes, &1))
      |> then(fn assigns ->
        update(assigns, :attributes, &Keyword.put(&1, :autocomplete, assigns.autocomplete))
      end)
      |> assign(:errors, errors)

    ~H"""
    <.element name={@name} errors={@errors}>
      <:label>
        <%= render_slot(@label) %>
      </:label>
      <%= Phoenix.HTML.Form.text_input(@form, @name, @attributes) %>
    </.element>
    """
  end

  attr(:type, :atom, default: :button)
  attr(:style, :atom, default: :default)
  attr(:size, :atom, default: :normal)
  attr(:class, :string, default: "")
  attr(:href, :string)
  slot(:inner_block, required: true)
  attr(:rest, :global)

  @default_classes "inline-block rounded"
  @styles %{
    default: "bg-pink-500 hover:bg-pink-600 text-true-gray-50",
    white: "bg-true-gray-100 text-true-gray-900 hover:bg-true-gray-200",
    clear: "bg-transparent text-true-gray-200 hover:text-pink-400",
    link: "bg-transparent text-pink-600 hover:text-pink-400",
    outline:
      "bg-transparent text-pink-500 border border-pink-500 hover:bg-pink-600 hover:border-pink-600 hover:text-white disabled:bg-true-gray-400 disabled:hover:bg-true-gray-400 disabled:text-true-gray-700 disabled:hover:text-true-gray-700 disabled:border-true-gray-400 disabled:hover:border-true-gray-400"
  }
  @sizes %{
    small: "py-1 px-2 h-8",
    normal: "py-1.5 px-3 h-10"
  }
  def button(%{href: _href} = assigns) do
    assigns = update_button_class(assigns)

    ~H"""
    <.link patch={@href} class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  def button(assigns) do
    assigns = update_button_class(assigns)

    ~H"""
    <button type={@type} class={@class} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  attr(:errors, :list)

  def field_errors(assigns) do
    ~H"""
    <%= if is_list(@errors) and Enum.any?(@errors) do %>
      <div class="flex flex-col text-sm text-right text-red-400">
      <%= for error <- @errors do %>
        <span><%= Galerie.Ecto.Changeset.format_error(error) %></span>
      <% end %>
      </div>
    <% end %>
    """
  end

  @button_styles ~w(style size)a
  defp update_button_class(assigns) do
    style_class =
      Enum.reduce(@button_styles, @default_classes, fn button_style, acc ->
        style_class = style_class(assigns, button_style)
        Html.class(acc, style_class)
      end)

    update(assigns, :class, fn class ->
      Html.class(style_class, class)
    end)
  end

  defp style_class(assigns, :style), do: Map.fetch!(@styles, Map.fetch!(assigns, :style))
  defp style_class(assigns, :size), do: Map.fetch!(@sizes, Map.fetch!(assigns, :size))
end
