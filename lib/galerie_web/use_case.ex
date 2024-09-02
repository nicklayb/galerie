defmodule GalerieWeb.UseCase do
  def execute(socket, use_case, params, options \\ []) do
    options = Keyword.put(options, :user, socket.assigns.current_user)
    use_case.execute(params, options)
  end
end
