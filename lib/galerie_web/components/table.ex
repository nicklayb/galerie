defmodule GalerieWeb.Components.Table do
  use Phoenix.Component

  alias Galerie.Repo.Page
  alias GalerieWeb.Html
  alias Phoenix.LiveView.AsyncResult
  import GalerieWeb.Gettext

  def render(assigns) do
    ~H"""
    <table class="w-full table-auto">
      <thead>
        <tr>
          <%= for cell <- @cell do %>
            <th class="text-left"><%= cell.header %></th>
          <% end %>
        </tr>
      </thead>
      <%= case @rows do %>
        <% %AsyncResult{result: %Page{results: [_ | _] = rows}, loading: loading} -> %>
          <tbody class={Html.class({loading, "opacity-60"})}>
            <%= for row <- rows do %>
              <tr class="border-b">
                <%= for cell <- @cell do %>
                  <td><%= render_slot(cell, row) %></td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        <% %AsyncResult{result: _, loading: loading} -> %>
          <tbody class={Html.class({loading, "opacity-60"})}>
            <tr>
              <td colspan={length(@cell)}><%= gettext("No record") %></td>
            </tr>
          </tbody>
      <% end %>
    </table>
    """
  end
end
