defmodule GalerieWeb.Gettext.Jobs do
  import GalerieWeb.Gettext
  @domain "jobs"

  def translate_job_state(:retryable), do: dgettext(@domain, "Retryable")
  def translate_job_state(:available), do: dgettext(@domain, "Available")
  def translate_job_state(:executing), do: dgettext(@domain, "Executing")
end
