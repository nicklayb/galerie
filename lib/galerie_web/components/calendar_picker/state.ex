defmodule GalerieWeb.Components.CalendarPicker.State do
  defstruct [:now, :date, :calendar, heatmap: %Galerie.Heatmap{}, highlighted_dates: MapSet.new()]

  alias Galerie.Heatmap
  alias GalerieWeb.Components.CalendarPicker.State

  def new(date, options \\ []) do
    now = Keyword.get(options, :now, Date.utc_today())

    %State{now: now}
    |> set_date(date)
    |> set_heatmap(Keyword.get(options, :heatmap, %Heatmap{}))
  end

  def toggle_only(%State{} = state, date) do
    update_highlighted_dates(state, fn highlighted_dates ->
      if MapSet.member?(highlighted_dates, date) do
        MapSet.new()
      else
        MapSet.new([date])
      end
    end)
  end

  def toggle(%State{} = state, date) do
    update_highlighted_dates(state, fn highlighted_dates ->
      MapSet.Extra.toggle(highlighted_dates, date)
    end)
  end

  def next_month(%State{date: date} = state) do
    set_date(state, Date.shift(date, month: 1))
  end

  def previous_month(%State{date: %Date{} = date} = state) do
    set_date(state, Date.shift(date, month: -1))
  end

  def set_year(%State{date: %Date{} = date} = state, year) do
    set_date(state, %Date{date | year: year})
  end

  def set_month(%State{date: %Date{} = date} = state, month) do
    set_date(state, %Date{date | month: month})
  end

  def set_heatmap(%State{date: %Date{} = date} = state, %Heatmap{} = heatmap) do
    {start_of_month, end_of_month} = month_range(date)
    month_range = Date.range(start_of_month, end_of_month)

    heatmap =
      Heatmap.filter(heatmap, fn key, _ ->
        Enum.member?(month_range, key)
      end)

    %State{state | heatmap: heatmap}
  end

  defp set_date(%State{} = state, date) do
    %State{state | date: date, calendar: build_calendar(date)}
  end

  @days_in_week 7
  defp build_calendar(%Date{} = date) do
    {start_of_calendar, end_of_calendar} = calendar_range(date)

    build_calendar(start_of_calendar, end_of_calendar, 0, {[], []})
  end

  defp build_calendar(end_of_calendar, end_of_calendar, _, {current_week, acc}) do
    Enum.reverse([Enum.reverse([end_of_calendar | current_week]) | acc])
  end

  defp build_calendar(current, end_of_calendar, current_day, {current_week, acc}) do
    current_week = [current | current_week]
    next_day = Date.add(current, 1)

    if current_day == 6 do
      build_calendar(next_day, end_of_calendar, 0, {[], [Enum.reverse(current_week) | acc]})
    else
      build_calendar(next_day, end_of_calendar, current_day + 1, {current_week, acc})
    end
  end

  defp calendar_range(date) do
    {start_of_month, end_of_month} = month_range(date)

    diff_with_first_sunday = -Date.day_of_week(start_of_month, :sunday) + 1

    diff_with_last_saturday = @days_in_week - Date.day_of_week(end_of_month, :sunday)

    start_of_calendar = Date.add(start_of_month, diff_with_first_sunday)
    end_of_calendar = Date.add(end_of_month, diff_with_last_saturday)

    {start_of_calendar, end_of_calendar}
  end

  defp month_range(%Date{} = date) do
    start_of_month = %Date{date | day: 1}
    end_of_month = %Date{date | day: Date.days_in_month(date)}
    {start_of_month, end_of_month}
  end

  defp update_highlighted_dates(%State{highlighted_dates: highlighted_dates} = state, function) do
    %State{state | highlighted_dates: function.(highlighted_dates)}
  end
end
