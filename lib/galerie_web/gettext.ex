defmodule GalerieWeb.Gettext do
  use Gettext.Backend, otp_app: :galerie

  defmacro __using__(_) do
    quote do
      use Gettext, backend: GalerieWeb.Gettext
    end
  end
end
