defmodule GalerieWeb.Components.CalendarPicker do
  use Phoenix.Component

  import GalerieWeb.Gettext

  alias Galerie.Heatmap
  alias GalerieWeb.Components.CalendarPicker.State
  alias GalerieWeb.Components.Icon
  alias GalerieWeb.Html

  @back "back"
  @next "next"
  @click "click"
  @month_changed "month-changed"
  @year_changed "year-changed"

  def new_state(date, options \\ []) do
    State.new(date, options)
  end

  def handle_event(%State{} = state, @back, _) do
    State.previous_month(state)
  end

  def handle_event(%State{} = state, @next, _) do
    State.next_month(state)
  end

  def handle_event(%State{} = state, @month_changed, %{"value" => month}) do
    State.set_month(state, String.to_integer(month))
  end

  def handle_event(%State{} = state, @year_changed, %{"value" => year}) do
    State.set_year(state, String.to_integer(year))
  end

  attr(:id, :string, required: true)
  attr(:calendar, State, required: true)
  attr(:event_prefix, :string, default: "calendar")

  def render(%{event_prefix: event_prefix, calendar: %State{date: date}} = assigns) do
    years =
      date
      |> years()
      |> Enum.map(&{&1, &1})

    months = Enum.with_index(months())

    assigns =
      assigns
      |> assign(:weekdays, weekdays())
      |> assign(:years, years)
      |> assign(:months, months)
      |> assign(:on_back, "#{event_prefix}:#{@back}")
      |> assign(:on_next, "#{event_prefix}:#{@next}")
      |> assign(:on_click, "#{event_prefix}:#{@click}")
      |> assign(:on_month_change, "#{event_prefix}:#{@month_changed}")
      |> assign(:on_year_change, "#{event_prefix}:#{@year_changed}")

    ~H"""
    <div class="flex flex-col py-2">
      <div class="flex flex-row items-center">
        <div class="w-30" phx-click={@on_back}><Icon.left_chevron width="20" height="20" /></div>
        <div class="flex flex-row flex-1">
          <.select id={@id} name="month" selected_value={@calendar.date.month} options={@months} on_change={@on_month_change} class="w-8/12"/>
          <.select id={@id} name="year" selected_value={@calendar.date.year} options={@years} on_change={@on_year_change} class="w-4/12"/>
        </div>
        <div class="w-30" phx-click={@on_next}><Icon.right_chevron width="20" height="20" /></div>
      </div>
      <div class="flex flex-row justify-between">
        <%= for day <- @weekdays do %>
          <div class="flex-1 text-center py-2"><%= String.at(day, 0) %></div>
        <% end %>
      </div>
      <%= for row <- @calendar.calendar do %>
        <div class="flex flex-row justify-between">
          <%= for %Date{day: day} = current_date <- row do %>
            <div class={Html.class("relative flex-1 group text-center py-1 flex flex-col items-center", {not current_month?(@calendar.date, current_date), "text-gray-400"})}>
              <div class="bg-gray-200 z-0 w-full h-full rounded-full absolute hidden group-hover:block"></div>
              <span class={Html.class("z-10", {current_date == @calendar.now, "font-bold"})}><%= day %></span>
              <span class="h-1 z-10 bg-red-600 rounded-full" style={heatmap_style(Heatmap.get(@calendar.heatmap, current_date, 0))}></span>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp select(assigns) do
    ~H"""
    <select class={Html.class("p-0", @class)} data-event={@on_change} phx-hook="Formless" id={"#{@id}:#{@name}"} name={@name}>
      <%= for {label, value} <- @options do %>
        <option value={value} selected={@selected_value == value}><%= label %></option>
      <% end %>
    </select>
    """
  end

  defp current_month?(%Date{month: left_month}, %Date{month: right_month}),
    do: left_month == right_month

  defp heatmap_style(nil), do: heatmap_style(Enum.random(0..5))
  defp heatmap_style(0), do: "width: 10%; background-color: #d7d7d7"
  defp heatmap_style(1), do: "width: 18%; background-color: #ebe465"
  defp heatmap_style(2), do: "width: 29%; background-color: #deaf50"
  defp heatmap_style(3), do: "width: 40%; background-color: #d68940"
  defp heatmap_style(4), do: "width: 60%; background-color: #d67740"
  defp heatmap_style(5), do: "width: 70%; background-color: #d65e40"

  @visible_years 30
  defp years(%Date{year: year}) do
    (year - @visible_years)..year
  end

  defp weekdays,
    do: [
      gettext("Sunday"),
      gettext("Monday"),
      gettext("Tuesday"),
      gettext("Wednesday"),
      gettext("Thursday"),
      gettext("Friday"),
      gettext("Saturday")
    ]

  defp months,
    do: [
      gettext("January"),
      gettext("Febuary"),
      gettext("March"),
      gettext("April"),
      gettext("May"),
      gettext("June"),
      gettext("July"),
      gettext("August"),
      gettext("September"),
      gettext("October"),
      gettext("November"),
      gettext("December")
    ]
end
