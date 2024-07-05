defmodule GalerieWeb.Components.Helpers do
  def class(left, ""), do: left
  def class("", right), do: right
  def class(left, right), do: Enum.join([left, right], " ")
end
