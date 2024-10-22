defmodule GalerieWeb.Components.Multiselect do
  use Phoenix.Component
  import GalerieWeb.Gettext

  alias GalerieWeb.Components.Multiselect.State, as: MultiselectState

  def new(options) do
    MultiselectState.new(options)
  end

  def selected_items(%MultiselectState{} = state), do: MultiselectState.selected_items(state)

  def handle_event("all", _, %MultiselectState{} = state) do
    MultiselectState.all(state)
  end

  def handle_event("none", _, %MultiselectState{} = state) do
    MultiselectState.clear(state)
  end

  def handle_event("change", %{"_target" => ["select"]} = params, %MultiselectState{} = state) do
    MultiselectState.update(state, Map.get(params, "select", []))
  end

  attr(:label, :string, default: "")
  attr(:state, MultiselectState, required: true)
  attr(:prefix, :string, required: true)
  attr(:target, :any, default: nil)

  def render(assigns) do
    assigns = assign(assigns, :refresh_id, Ecto.UUID.generate())

    ~H"""
    <form phx-change={"#{@prefix}:change"} class="w-full" phx-target={@target}>
      <div class="flex justify-between text-true-gray-700">
        <div class="flex items-center">
          <%= @label %>
          <%= if @state.count > 0 do %>
            <span class="ml-1 flex justify-center items-center w-4 h-4 text-sm bg-pink-400 text-white rounded-full"><%= @state.count %></span>
          <% end %>
        </div>
        <div class="text-sm flex items-end">
          <a class="mr-2" href="#" phx-click={"#{@prefix}:all"} phx-target={@target}><%= gettext("All") %></a>
          <a href="#" phx-click={"#{@prefix}:none"} phx-target={@target}><%= gettext("None") %></a>
        </div>
      </div>
      <select multiple name="select[]" class="w-full p-0 rounded-md" id={@refresh_id}>
        <%= for {_, key, name} <- @state.options do %>
          <option value={key} selected={MultiselectState.selected?(@state, key)}><%= name %></option>
        <% end %>
      </select>
    </form>
    """
  end
end
