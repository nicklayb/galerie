defmodule GalerieWeb.Components.Form do
  use Phoenix.Component
  alias GalerieWeb.Components.Helpers

  attr(:name, :atom, required: true)
  attr(:label, :string, required: true)
  attr(:errors, :list, default: [])
  slot(:inner_block, required: true)

  def element(assigns) do
    ~H"""
    <div class={"group mb-3 flex flex-col gap-y-2 " <> if Enum.any?(@errors), do: "has-errors", else: ""}>
      <%= if @label do %>
        <label for={@name} class="text-sm pl-0.5 group-[.has-errors]:text-red-400">
          <%= @label %>
        </label>
      <% end %>
      <%= render_slot(@inner_block) %>
      <.field_errors errors={@errors} />
    </div>
    """
  end

  attr(:form, :any, default: nil)
  attr(:class, :string, default: "")
  attr(:name, :atom)
  attr(:field, :any)
  attr(:label, :string, default: nil)
  attr(:autocomplete, :string, default: "")
  attr(:rest, :global)

  @class "block w-full bg-true-gray-100 rounded border-0 py-1.5 pr-20 text-true-gray-900 ring-1 ring-inset ring-true-gray-500 placeholder:text-true-gray-400 focus:ring-2 focus:ring-inset focus:ring-pink-600 sm:text-sm sm:leading-6 group-[.has-errors]:ring-red-400"
  def text_input(%{field: _field} = assigns) do
    assigns = update(assigns, :class, &Helpers.class(@class, &1))

    ~H"""
    <.element name={@field.name} label={@label} errors={@field.errors}>
      <input type="text" id={@field.id} name={@field.name} value={@field.value} class={@class} autocomplete={@autocomplete} {@rest} />
    </.element>
    """
  end

  def text_input(%{rest: rest, class: class, form: form, name: name} = assigns) do
    classes = Helpers.class(@class, class)

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
    <.element name={@name} label={@label} errors={@errors}>
      <%= Phoenix.HTML.Form.text_input(@form, @name, @attributes) %>
    </.element>
    """
  end

  attr(:type, :atom, default: :button)
  attr(:style, :atom, default: :default)
  attr(:class, :string, default: "")
  attr(:href, :string)
  slot(:inner_block, required: true)
  attr(:rest, :global)

  @default_classes "inline-block py-1.5 px-3 h-10 rounded"
  @classes %{
    default: "bg-pink-500 hover:bg-pink-600 text-true-gray-50",
    white: "bg-true-gray-100 text-true-gray-900 hover:bg-true-gray-200",
    clear: "bg-transparent text-true-gray-200 hover:text-pink-400",
    link: "bg-transparent text-pink-600 hover:text-pink-400",
    outline:
      "bg-transparent text-true-gray-100 border border-true-gray-100 hover:border-pink-400 hover:text-pink-400"
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

  defp update_button_class(%{style: style} = assigns) do
    update(assigns, :class, fn class ->
      @classes
      |> Map.fetch!(style)
      |> then(&Helpers.class(@default_classes, &1))
      |> Helpers.class(class)
    end)
  end
end
