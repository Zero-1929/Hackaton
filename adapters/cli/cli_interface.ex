defmodule Adapters.CLI.Interface do
  alias Adapters.Persistence.ETSRepo

  @welcome """
  ==========================================
            🚀 HACKATHON CLI APP
  ==========================================
  Escribe /help para ver los comandos
  Escribe /quit para salir
  ==========================================
  """

  # PUNTO DE ENTRADA PRINCIPAL
  def start() do
    IO.puts(@welcome)

    Adapters.Persistence.ETSRepo.start_link()
    repo = Adapters.Persistence.ETSRepo


    # Podrías pedir login, pero por ahora usamos un usuario fijo
    user = %{id: "user_1", name: "Invitado"}

    loop(repo, user)
  end

  # LOOP PRINCIPAL DE LA TERMINAL
  defp loop(repo, user) do
    cmd =
      IO.gets("> ")
      |> to_string()
      |> String.trim()

    CommandHandler.handle(cmd, repo, user)

    loop(repo, user)  # repetir indefinidamente
  end
end
