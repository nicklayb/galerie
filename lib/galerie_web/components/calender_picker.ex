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

  def put_heatmap(%State{} = state, %Galerie.Heatmap{} = heatmap) do
    State.set_heatmap(state, heatmap)
  end

  def toggle_date(%State{} = state, date, options) do
    if Keyword.fetch!(options, :only?) do
      State.toggle_only(state, date)
    else
      State.toggle(state, date)
    end
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
    <div class="flex flex-col pb-2">
      <div class="flex flex-row items-center bg-gray-100 border-b border-gray-300">
        <.arrow on_click={@on_back} icon={:left_chevron} />
        <div class="flex flex-row flex-1">
          <.select id={@id} name="month" selected_value={@calendar.date.month} options={@months} on_change={@on_month_change} class="w-8/12"/>
          <.select id={@id} name="year" selected_value={@calendar.date.year} options={@years} on_change={@on_year_change} class="w-4/12"/>
        </div>
        <.arrow on_click={@on_next} icon={:right_chevron} />
      </div>
      <div class="flex flex-row justify-between">
        <%= for day <- @weekdays do %>
          <div class="flex-1 text-center py-2"><%= String.at(day, 0) %></div>
        <% end %>
      </div>
      <%= for row <- @calendar.calendar do %>
        <div class="flex flex-row justify-between">
          <%= for %Date{} = current_date <- row do %>
            <.day calendar={@calendar} current_date={current_date} on_click={@on_click} />
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @class "relative flex-1 group text-center py-1 flex flex-col items-center rounded-sm border border-transparent"
  defp day(%{calendar: calendar, current_date: current_date} = assigns) do
    off_month? = not current_month?(calendar.date, current_date)
    highlighted? = MapSet.member?(calendar.highlighted_dates, current_date)

    heatmap_style =
      calendar.heatmap
      |> Heatmap.get(current_date, 0)
      |> heatmap_style()

    assigns =
      assigns
      |> assign(:current_date?, current_date == calendar.now)
      |> assign(:heatmap_style, heatmap_style)
      |> assign(:class, @class)
      |> update(:class, &Html.class(&1, {off_month?, "text-gray-400"}))
      |> update(
        :class,
        &Html.class(&1, {highlighted?, "border-pink-400", "hover:border-gray-200"})
      )

    ~H"""
    <div class={@class} phx-click={@on_click} phx-value-date={@current_date}>
      <span class={Html.class("z-5", {@current_date?, "font-bold"})}><%= @current_date.day %></span>
      <span class="h-1 z-1 bg-red-600 rounded-full" style={@heatmap_style}></span>
    </div>
    """
  end

  defp arrow(assigns) do
    ~H"""
    <div class="w-7 h-7 flex items-center justify-center hover:bg-gray-200" phx-click={@on_click}><Icon.icon icon={@icon} width="16" height="16" /></div>
    """
  end

  defp select(assigns) do
    ~H"""
    <select class={Html.class("p-0 pl-1 text-sm border-0 py-1 bg-gray-100 hover:bg-gray-200", @class)} data-event={@on_change} phx-hook="Formless" id={"#{@id}:#{@name}"} name={@name}>
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
