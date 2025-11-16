# Archivo: hackathon_cli.ex
# Ejecútalo con: elixir hackathon_cli.ex

# Repositorio simple usando GenServer + ETS
defmodule ETSRepo do
  use GenServer

  ## API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def save_participant(participant), do: GenServer.call(__MODULE__, {:save_participant, participant})
  def list_participants(), do: GenServer.call(__MODULE__, :list_participants)
  def get_participant(id), do: GenServer.call(__MODULE__, {:get_participant, id})

  def save_team(team), do: GenServer.call(__MODULE__, {:save_team, team})
  def list_teams(), do: GenServer.call(__MODULE__, :list_teams)
  def get_team(id), do: GenServer.call(__MODULE__, {:get_team, id})

  def save_announcement(announcement), do: GenServer.call(__MODULE__, {:save_announcement, announcement})
  def list_announcements(limit), do: GenServer.call(__MODULE__, {:list_announcements, limit})

  ## Callbacks
  def init(_state) do
    # Crear tablas ETS para persistencia en memoria
    participants = :ets.new(:participants, [:named_table, :set, :public, read_concurrency: true])
    teams = :ets.new(:teams, [:named_table, :set, :public, read_concurrency: true])
    announcements = :ets.new(:announcements, [:named_table, :ordered_set, :public])

    {:ok, %{participants: participants, teams: teams, announcements: announcements}}
  end

  def handle_call({:save_participant, participant}, _from, state) do
    :ets.insert(:participants, {participant.id, participant})
    {:reply, :ok, state}
  end

  def handle_call(:list_participants, _from, state) do
    participants = :ets.tab2list(:participants) |> Enum.map(fn {_k, v} -> v end)
    {:reply, participants, state}
  end

  def handle_call({:get_participant, id}, _from, state) do
    case :ets.lookup(:participants, id) do
      [{^id, participant}] -> {:reply, participant, state}
      [] -> {:reply, nil, state}
    end
  end

  def handle_call({:save_team, team}, _from, state) do
    :ets.insert(:teams, {team.id, team})
    {:reply, :ok, state}
  end

  def handle_call(:list_teams, _from, state) do
    teams = :ets.tab2list(:teams) |> Enum.map(fn {_k, v} -> v end)
    {:reply, teams, state}
  end

  def handle_call({:get_team, id}, _from, state) do
    case :ets.lookup(:teams, id) do
      [{^id, team}] -> {:reply, team, state}
      [] -> {:reply, nil, state}
    end
  end

  def handle_call({:save_announcement, announcement}, _from, state) do
    # clave incremental: timestamp + uniq
    key = {System.system_time(:millisecond), :erlang.unique_integer([:positive])}
    :ets.insert(:announcements, {key, announcement})
    {:reply, :ok, state}
  end

  def handle_call({:list_announcements, limit}, _from, state) do
    announcements =
      :ets.tab2list(:announcements)
      |> Enum.sort_by(fn {{ts, uniq}, _ann} -> {-ts, -uniq} end)
      |> Enum.take(limit)
      |> Enum.map(fn {_k, v} -> v end)

    {:reply, announcements, state}
  end
end

# Modelos simples
defmodule Participante do
  defstruct [:id, :nombre, :email]

  def registrar(nombre, email) do
    id = "p_" <> Base.encode16(:crypto.strong_rand_bytes(4), case: :lower)
    %Participante{id: id, nombre: nombre, email: email}
  end
end

defmodule Equipo do
  defstruct [:id, :nombre, :tema, :miembros, :activo]

  def crear(id, nombre, tema, miembros \\ []) do
    %Equipo{id: id, nombre: nombre, tema: tema, miembros: miembros || [], activo: true}
  end

  def asignar_participante(%Equipo{miembros: miembros} = equipo, participante) do
    miembros_ids = Enum.map(miembros || [], & &1.id)

    if participante.id in miembros_ids do
      {:error, :already_member}
    else
      updated = %{equipo | miembros: (miembros || []) ++ [participante]}
      {:ok, updated}
    end
  end
end

# Servicio de chat / anuncios
defmodule ChatService do
  def open_chat(repo, team_id, user) do
    team = ETSRepo.get_team(team_id)

    if team == nil do
      IO.puts("❌ Equipo no encontrado: #{team_id}")
      :error
    else
      IO.puts("💬 Chat abierto para #{team.nombre} (ID: #{team.id}) — escribe 'exit' para salir")
      chat_loop(repo, team, user)
    end
  end

  defp chat_loop(repo, team, user) do
    input = Seed.gets_safe("[#{team.nombre}] #{user.name}: ")

    case input do
      nil -> :ok
      "exit" -> IO.puts("Saliendo del chat...")
      ":exit" -> IO.puts("Saliendo del chat...")
      msg when is_binary(msg) ->
        if String.trim(msg) == "" do
          chat_loop(repo, team, user)
        else
        announcement = %{
          remitente: user.name,
          remitente_id: user.id,
          contenido: msg,
          fecha_hora: DateTime.utc_now() |> DateTime.to_string(),
          team_id: team.id
        }

        ETSRepo.save_announcement(announcement)
        IO.puts("[#{announcement.fecha_hora}] #{announcement.remitente}: #{announcement.contenido}")
        chat_loop(repo, team, user)
        end
      end
  end

  def send_announcement(_repo, user, content) do
    announcement = %{
      remitente: user.name,
      remitente_id: user.id,
      contenido: content,
      fecha_hora: DateTime.utc_now() |> DateTime.to_string()
    }

    ETSRepo.save_announcement(announcement)
    IO.puts("✅ Anuncio enviado.")
  end

  def get_announcements(_repo, limit \\ 10) do
    {:ok, ETSRepo.list_announcements(limit)}
  rescue
    _ -> {:error, :repo_error}
  end
end

# Semilla de datos
defmodule Seed do
  def load_sample_data() do
    IO.puts("📦 Cargando datos de ejemplo...")

    participantes = [
      Participante.registrar("Ana García", "ana@hackathon.com"),
      Participante.registrar("Carlos López", "carlos@hackathon.com"),
      Participante.registrar("María Rodríguez", "maria@hackathon.com"),
      Participante.registrar("Juan Pérez", "juan@hackathon.com"),
      Participante.registrar("Laura Martínez", "laura@hackathon.com")
    ]

    Enum.each(participantes, &ETSRepo.save_participant/1)

    equipos = [
      Equipo.crear("team_1", "Code Masters", "Desarrollo Web", [Enum.at(participantes, 0), Enum.at(participantes, 1)]),
      Equipo.crear("team_2", "Data Wizards", "Machine Learning", [Enum.at(participantes, 2), Enum.at(participantes, 3)]),
      Equipo.crear("team_3", "Mobile Heroes", "Apps Móviles", [Enum.at(participantes, 4)])
    ]

    Enum.each(equipos, &ETSRepo.save_team/1)

    IO.puts("✅ Datos de ejemplo cargados: #{length(participantes)} participantes, #{length(equipos)} equipos")
  end

  # Helper for safe input
  def gets_safe(prompt) do
    case IO.gets(prompt) do
      nil -> nil
      data -> String.trim(data)
    end
  end
end

# Router/CLI para comandos
defmodule CLI do
  def show_menu do
    IO.puts("\n📋 MENÚ PRINCIPAL:")
    IO.puts("1. list_teams        - Listar todos los equipos")
    IO.puts("2. list_participants - Listar todos los participantes")
    IO.puts("3. create_team       - Crear un nuevo equipo")
    IO.puts("4. join_team         - Unirse a un equipo")
    IO.puts("5. open_chat         - Abrir chat de equipo")
    IO.puts("6. send_announcement - Enviar anuncio general")
    IO.puts("7. show_announcements- Ver anuncios")
    IO.puts("8. create_participant- Crear nuevo participante")
    IO.puts("9. help              - Mostrar ayuda")
    IO.puts("10. quit             - Salir")
    IO.puts("")
  end

  def read_command do
    case IO.gets("👉 Elige una opción: ") do
      nil -> :quit
      cmd ->
        cmd = String.trim(cmd)

        case cmd do
          "1" -> :list_teams
          "2" -> :list_participants
          "3" -> :create_team
          "4" -> :join_team
          "5" -> :open_chat
          "6" -> :send_announcement
          "7" -> :show_announcements
          "8" -> :create_participant
          "9" -> :help
          "10" -> :quit
          "list_teams" -> :list_teams
          "list_participants" -> :list_participants
          "create_team" -> :create_team
          "join_team" -> :join_team
          "open_chat" -> :open_chat
          "send_announcement" -> :send_announcement
          "show_announcements" -> :show_announcements
          "create_participant" -> :create_participant
          "help" -> :help
          "quit" -> :quit
          _ -> :invalid_command
        end
    end
  end
end

# Módulo principal
defmodule Main do
  @welcome """
  ╔══════════════════════════════════════════════════════════════╗
  ║                    🚀 HACKATHON MANAGER 🚀                    ║
  ║                                                              ║
  ║  Sistema completo de gestión para hackathons                 ║
  ║  - Gestión de equipos y participantes                       ║
  ║  - Sistema de chat en tiempo real                            ║
  ║  - Mentores y proyectos (básico)                             ║
  ║                                                              ║
  ║  Escribe 'help' para ver los comandos disponibles             ║
  ║  Escribe 'quit' para salir                                   ║
  ╚══════════════════════════════════════════════════════════════╝
  """

  def start do
    IO.puts(@welcome)

    case ETSRepo.start_link([]) do
      {:ok, _pid} ->
        Seed.load_sample_data()
        main_loop()

      {:error, reason} ->
        IO.puts("❌ Error al iniciar ETSRepo: #{inspect(reason)}")
    end
  end

  defp get_current_user do
    %{id: "user_1", name: "Administrador", role: :admin}
  end

  defp main_loop do
    user = get_current_user()

    CLI.show_menu()

    case CLI.read_command() do
      :quit -> IO.puts("👋 ¡Hasta luego!")
      :help ->
        CLI.show_menu()
        main_loop()

      :list_teams ->
        list_teams()
        main_loop()

      :list_participants ->
        list_participants()
        main_loop()

      :create_team ->
        create_team_interactive()
        main_loop()

      :join_team ->
        join_team_interactive()
        main_loop()

      :open_chat ->
        open_chat_interactive(user)
        main_loop()

      :send_announcement ->
        send_announcement_interactive(user)
        main_loop()

      :show_announcements ->
        show_announcements()
        main_loop()

      :create_participant ->
        create_participant_interactive()
        main_loop()

      :invalid_command ->
        IO.puts("❌ Comando no válido. Escribe 'help' para ver los comandos disponibles.")
        main_loop()
    end
  end

  defp list_teams do
    IO.puts("\n🏆 EQUIPOS REGISTRADOS:")
    IO.puts(String.duplicate("=", 50))

    teams = ETSRepo.list_teams()

    if Enum.empty?(teams) do
      IO.puts("No hay equipos registrados.")
    else
      Enum.each(teams, fn team ->
        status = if team.activo, do: "✅ Activo", else: "❌ Inactivo"
        members_count = length(team.miembros || [])
        IO.puts("📋 #{team.nombre}")
        IO.puts("   ID: #{team.id}")
        IO.puts("   Tema: #{team.tema}")
        IO.puts("   Miembros: #{members_count}")
        IO.puts("   Estado: #{status}")
        IO.puts(String.duplicate("-", 40))
      end)
    end
  end

  defp list_participants do
    IO.puts("\n👥 PARTICIPANTES REGISTRADOS:")
    IO.puts(String.duplicate("=", 50))

    participants = ETSRepo.list_participants()

    if Enum.empty?(participants) do
      IO.puts("No hay participantes registrados.")
    else
      Enum.each(participants, fn p ->
        IO.puts("👤 #{p.nombre}")
        IO.puts("   ID: #{p.id}")
        IO.puts("   Email: #{p.email}")
        IO.puts(String.duplicate("-", 40))
      end)
    end
  end

  defp create_team_interactive do
    IO.puts("\n🏆 CREAR NUEVO EQUIPO:")

    name = IO.gets("📝 Nombre del equipo: ") |> maybe_trim()
    theme = IO.gets("🎯 Tema del proyecto: ") |> maybe_trim()

    if name == "" or theme == "" do
      IO.puts("❌ El nombre y el tema son obligatorios.")
    else
      team_id = "team_" <> Base.encode16(:crypto.strong_rand_bytes(4), case: :lower)
      new_team = Equipo.crear(team_id, name, theme, [])

      case ETSRepo.save_team(new_team) do
        :ok -> IO.puts("✅ Equipo '#{name}' creado exitosamente con ID: #{team_id}")
        other -> IO.puts("❌ Error al crear el equipo: #{inspect(other)}")
      end
    end
  end

  defp join_team_interactive do
    IO.puts("\n👥 UNIRSE A UN EQUIPO:")

    teams = ETSRepo.list_teams() |> Enum.filter(& &1.activo)

    if Enum.empty?(teams) do
      IO.puts("❌ No hay equipos activos disponibles.")
    else
      IO.puts("Equipos disponibles:")
      Enum.each(teams, fn team ->
        IO.puts("  #{team.id} - #{team.nombre} (#{team.tema})")
      end)

      team_id = IO.gets("📝 ID del equipo: ") |> maybe_trim()
      participant_id = IO.gets("👤 ID del participante: ") |> maybe_trim()

      case ETSRepo.get_team(team_id) do
        nil -> IO.puts("❌ Equipo no encontrado.")
        team ->
          case ETSRepo.get_participant(participant_id) do
            nil -> IO.puts("❌ Participante no encontrado.")
            participant ->
              case Equipo.asignar_participante(team, participant) do
                {:error, :already_member} -> IO.puts("⚠️ Este participante ya está en el equipo.")
                {:ok, updated_team} ->
                  ETSRepo.save_team(updated_team)
                  IO.puts("✅ #{participant.nombre} se ha unido al equipo #{team.nombre}")
              end
          end
      end
    end
  end

  defp open_chat_interactive(user) do
    IO.puts("\n💬 ABRIR CHAT DE EQUIPO:")

    teams = ETSRepo.list_teams() |> Enum.filter(& &1.activo)

    if Enum.empty?(teams) do
      IO.puts("❌ No hay equipos activos disponibles.")
    else
      IO.puts("Equipos disponibles:")
      Enum.each(teams, fn team -> IO.puts("  #{team.id} - #{team.nombre}") end)

      team_id = IO.gets("📝 ID del equipo: ") |> maybe_trim()
      ChatService.open_chat(ETSRepo, team_id, user)
    end
  end

  defp send_announcement_interactive(user) do
    IO.puts("\n📢 ENVIAR ANUNCIO:")

    content = IO.gets("📝 Contenido del anuncio: ") |> maybe_trim()

    if content == "" do
      IO.puts("❌ El contenido del anuncio no puede estar vacío.")
    else
      ChatService.send_announcement(ETSRepo, user, content)
    end
  end

  defp show_announcements do
    IO.puts("\n📢 ANUNCIOS RECIENTES:")
    IO.puts(String.duplicate("=", 50))

    case ChatService.get_announcements(ETSRepo, 10) do
      {:ok, announcements} ->
        if Enum.empty?(announcements) do
          IO.puts("No hay anuncios recientes.")
        else
          Enum.each(announcements, fn a ->
            IO.puts("[#{a.fecha_hora}] #{a.remitente}:")
            IO.puts("  #{a.contenido}")
            IO.puts("")
          end)
        end

      {:error, reason} ->
        IO.puts("❌ Error al obtener anuncios: #{inspect(reason)}")
    end
  end

  defp create_participant_interactive do
    IO.puts("\n👤 CREAR NUEVO PARTICIPANTE:")

    name = IO.gets("📝 Nombre: ") |> maybe_trim()
    email = IO.gets("📧 Email: ") |> maybe_trim()

    if name == "" or email == "" do
      IO.puts("❌ El nombre y el email son obligatorios.")
    else
      participant = Participante.registrar(name, email)
      case ETSRepo.save_participant(participant) do
        :ok -> IO.puts("✅ Participante '#{name}' creado exitosamente con ID: #{participant.id}")
        other -> IO.puts("❌ Error al crear participante: #{inspect(other)}")
      end
    end
  end

  defp maybe_trim(nil), do: ""
  defp maybe_trim(value), do: String.trim(value)
end

# Arranque si el archivo se ejecuta directamente
if function_exported?(Main, :start, 0) do
  Main.start()
end
