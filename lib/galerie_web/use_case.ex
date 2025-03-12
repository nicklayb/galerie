defmodule GalerieWeb.UseCase do
  def execute(socket, use_case, params, options \\ []) do
    options = Keyword.put(options, :user, socket.assigns.current_user)
    Galerie.UseCase.execute(use_case, params, options)
  end
end
