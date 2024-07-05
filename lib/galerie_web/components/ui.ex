defmodule GalerieWeb.Components.Ui do
  use Phoenix.Component

  alias GalerieWeb.Components.Form
  alias GalerieWeb.Components.Helpers
  alias GalerieWeb.Components.Icon
  alias Phoenix.LiveView.JS

  def logo(assigns) do
    ~H"""
    <h1 class="text-4xl font-bold uppercase tracking-wide">Galerie</h1>
    """
  end

  slot(:inner_block, required: true)

  def list_item(assigns) do
    ~H"""
    <div class="p-3 bg-gray-200 mb-2 rounded-md shadow-md border border-gray-400">
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  slot(:inner_block, required: true)

  attr(:loading, :boolean, default: false)

  def resource(assigns) do
    ~H"""
    <.loading loading={@loading}>
      <%= case @resource do %>
        <% {:ok, record} -> %>
          <%= render_slot(@inner_block, record) %>

        <% {:error, error} -> %>
          <.resource_error error={error} />
      <% end %>
    </.loading>
    """
  end

  def resource_error(assigns) do
    ~H"""
    <%= case @error do %>
      <% :not_found -> %>
        <div class="">The requested resource could not be found</div>
      <% :unknown -> %>
        <div class="">Something happened when requesting the resource, try again.</div>
    <% end %>
    """
  end

  slot(:inner_block, required: true)
  attr(:class, :string, default: "")

  def main_title(assigns) do
    ~H"""
    <h2 class={Helpers.class("text-3xl font-bold text-true-gray-100", @class)}>
      <%= render_slot(@inner_block) %>
    </h2>
    """
  end

  slot(:inner_block, required: true)
  attr(:class, :string, default: "")

  def sub_title(assigns) do
    ~H"""
    <h3 class={Helpers.class("text-2xl font-bold text-gray-700 mb-2", @class)}>
      <%= render_slot(@inner_block) %>
    </h3>
    """
  end

  def side_menu(assigns) do
    ~H"""
    <div class="flex">
      <div class="flex-none w-64 flex flex-col">
        <%= for item <- @item do %>
          <a href="#" phx-click="change_tab" phx-value-tab={item.key} class={"px-3 py-2 " <> if item.key == @active, do: "bg-gray-700 text-white shadow-md rounded-md", else: ""}>
            <%= item.title %>
          </a>
        <% end %>
      </div>
      <div class="flex-1 ml-4">
        <%= case Enum.find(@item, &(&1.key == @active)) do %>
          <% %{inner_block: _} = tab-> %>
            <%= render_slot(tab) %>

          <% _ -> %>
            No active tab
        <% end %>
      </div>
    </div>
    """
  end

  slot(:inner_block, required: true)
  attr(:loading, :boolean, default: false)

  def loading(assigns) do
    ~H"""
    <%= if @loading do %>
      <div class="">
        <Icon.loading />
      </div>
    <% else %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  attr(:value, :integer, required: true)

  def progress(assigns) do
    ~H"""
    <div class="w-full bg-gray-200 rounded-full h-1.5 mb-2 dark:bg-gray-700">
      <div class="bg-purple-600 h-1.5 rounded-full dark:bg-purple-500" style={"width: #{@value}%"}></div>
    </div>
    """
  end

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr(:id, :string, required: true)
  attr(:show, :boolean, default: false)
  attr(:on_cancel, JS, default: %JS{})

  slot(:header, required: true) do
    attr(:class, :string)
  end

  slot(:body, required: true) do
    attr(:class, :string)
  end

  slot(:footer, required: false) do
    attr(:class, :string)
  end

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      tabindex="-1"
      aria-hidden="true"
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="bg-true-gray-900/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <div
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="relative hidden rounded bg-true-gray-900 border-true-gray-500 shadow-xl border transition"
            >
              <%= with [%{__slot__: _} = slot] <- @header do %>
                <div class={Helpers.class("flex items-center justify-between p-4", Map.get(slot, :class, ""))}>
                  <%= render_slot(@header) %>
                  <Form.button
                    style={:clear}
                    phx-click={JS.exec("data-cancel", to: "##{@id}")}
                    phx-value-state="false"
                >
                    <Icon.cross width="10" height="10"/>
                    <span class="sr-only">Close modal</span>
                  </Form.button>
                </div>
              <% end %>
              <%= with [%{__slot__: _} = slot] <- @body do %>
                <div id={"#{@id}-content"} class={Helpers.class("p-4 space-y-6", Map.get(slot, :class, ""))}>
                  <%= render_slot(@body) %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end
end
