defmodule GalerieWeb.Gettext.Picture do
  import GalerieWeb.Gettext

  def translate_filter(:ratings), do: gettext("Ratings")
  def translate_filter(:lens_models), do: gettext("Lens models")
  def translate_filter(:focal_lengths), do: gettext("Focal length")
  def translate_filter(:camera_models), do: gettext("Camera models")
  def translate_filter(:f_numbers), do: gettext("F number")
  def translate_filter(:exposure_times), do: gettext("Exposure times")

  def translate_metadata(:lens_model), do: gettext("Lens model")
  def translate_metadata(:focal_length), do: gettext("Focal length")
  def translate_metadata(:camera_make), do: gettext("Camera make")
  def translate_metadata(:camera_model), do: gettext("Camera model")
  def translate_metadata(:f_number), do: gettext("F number")
  def translate_metadata(:exposure_time), do: gettext("Exposure time")
end
