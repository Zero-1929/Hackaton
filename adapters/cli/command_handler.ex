defmodule Adapters.CLI.CommandHandler do
  @moduledoc """
  Manejador de comandos para la interfaz CLI
  """

  alias Adapters.Persistence.ETSRepo

  # ======================================================
  # PUNTO DE ENTRADA (router principal de comandos)
  # ======================================================

  def handle("/help", _repo, _user) do
    print_help()
  end

  # ------------------------------
  # /teams
  # ------------------------------
  def handle("/teams", _repo, _user) do
    teams = ETSRepo.list_teams()

    if teams == [] do
      IO.puts("📭 No hay equipos registrados.\n")
    else
      IO.puts("📋 Equipos registrados:")
      Enum.each(teams, fn team ->
        IO.puts("- #{team.name} (ID: #{team.id}, Categoría: #{team.category})")
      end)
      IO.puts("")
    end
  end

  # ------------------------------
  # /participants  (opcional)
  # ------------------------------
  def handle("/participants", _repo, _user) do
    parts = ETSRepo.list_participants()

    IO.puts("👥 Participantes:")
    Enum.each(parts, fn p -> IO.puts("- #{p.name} (#{p.id})") end)
    IO.puts("")
  end

  # ------------------------------
  # /mentors  (opcional)
  # ------------------------------
  def handle("/mentors", _repo, _user) do
    mentors = ETSRepo.list_mentors()

    IO.puts("🎓 Mentores registrados:")
    Enum.each(mentors, fn m -> IO.puts("- #{m.name} (#{m.id})") end)
    IO.puts("")
  end

  # ------------------------------
  # /join <equipo>
  # ------------------------------
  def handle("/join " <> team_name, repo, user) do
    case TeamService.join_team(repo, team_name, user) do
      {:ok, team} ->
        IO.puts("✅ Te uniste al equipo #{team.name}.\n")

      {:error, :not_found} ->
        IO.puts("❌ No existe un equipo con ese nombre.\n")

      {:error, reason} ->
        IO.puts("❌ No se pudo unir al equipo: #{inspect(reason)}\n")
    end
  end

  # ------------------------------
  # /project <equipo>
  # ------------------------------
  def handle("/project " <> team_name, repo, _user) do
    case ProjectService.get_project_by_team_name(repo, team_name) do
      nil ->
        IO.puts("📭 Ese equipo no tiene un proyecto registrado.\n")

      project ->
        IO.puts("""
        📌 Proyecto del equipo #{team_name}:
        -------------------------------------
        Nombre:      #{project.name}
        Categoría:   #{project.category}
        Descripción: #{project.description}
        Avance:      #{project.progress}%
        """)
    end
  end

  # ------------------------------
  # /chat <equipo>
  # ------------------------------
  def handle("/chat " <> team_name, repo, user) do
    ChatService.open_chat(repo, team_name, user)
  end

  # ======================================================
  # COMANDOS OPCIONALES PARA DESARROLLO
  # ======================================================

  # ------------------------------
  # /create_team <name> <category>
  # ------------------------------
  def handle("/create_team " <> args, repo, _user) do
    case String.split(args, " ") do
      [name, category] ->
        TeamService.create_team(repo, name, category)
        IO.puts("✅ Equipo creado correctamente.\n")

      _ ->
        IO.puts("❌ Uso correcto: /create_team <nombre> <categoria>\n")
    end
  end

  # ------------------------------
  # /create_project <team> <name> <category> <desc...>
  # Ej: /create_project EquipoX Sistema IA "Proyecto genial"
  # ------------------------------
  def handle("/create_project " <> args, repo, _user) do
    parts = String.split(args, " ")

    case parts do
      [team, name, category | desc_parts] ->
        desc = Enum.join(desc_parts, " ")
        ProjectService.create_project(repo, team, name, category, desc)
        IO.puts("✅ Proyecto creado correctamente.\n")

      _ ->
        IO.puts("❌ Uso correcto: /create_project <equipo> <nombre> <categoria> <descripcion>\n")
    end
  end

  # ------------------------------
  # /quit
  # ------------------------------
  def handle("/quit", _repo, _user) do
    IO.puts("👋 Saliendo del programa...")
    System.halt(0)
  end

  # ======================================================
  # Fallback - comando desconocido
  # ======================================================
  def handle(_cmd, _repo, _user) do
    IO.puts("❌ Comando no reconocido. Usa /help para ver opciones.\n")
  end

  # ======================================================
  # Función auxiliar para mostrar /help
  # ======================================================
  defp print_help() do
    IO.puts("""
    📖 Lista de comandos disponibles

      /teams                         → Listar equipos
      /join <equipo>                 → Unirse a un equipo
      /project <equipo>              → Ver proyecto del equipo
      /chat <equipo>                 → Abrir chat del equipo

    🔧 Comandos útiles para desarrollo
      /participants                  → Listar participantes
      /mentors                       → Listar mentores
      /create_team <nombre> <cat>    → Crear equipo
      /create_project ...            → Crear proyecto

    ❌ Otros
      /quit                          → Salir
      /help                          → Mostrar esta ayuda

    """)
  end
end
