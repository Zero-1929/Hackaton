# Adapters/CLI/command_handler.ex
defmodule Adapters.CLI.CommandHandler do
  @moduledoc """
  Manejador de comandos del CLI
  Procesa los comandos ingresados por el usuario
  """

  alias Services.{EquipoService, ProyectoService, ChatService, MentorService}
  alias Adapters.Persistence.ETSRepo

  @doc "Procesa un comando ingresado por el usuario"
  def handle(comando, usuario) do
    case String.split(comando, " ", parts: 2) do
      ["/help"] -> mostrar_ayuda()
      ["/teams"] -> listar_equipos()
      ["/join", nombre_equipo] -> unirse_equipo(nombre_equipo, usuario)
      ["/project", nombre_equipo] -> ver_proyecto(nombre_equipo)
      ["/chat", nombre_equipo] -> abrir_chat(nombre_equipo, usuario)
      ["/quit"] -> salir()
      [""] -> :ok
      _ -> comando_invalido(comando)
    end
  end

  # ============================================================================
  # Comandos Principales
  # ============================================================================

  defp mostrar_ayuda do
    IO.puts("""

    ╔══════════════════════════════════════════════════════════════╗
    ║                   📋 COMANDOS DISPONIBLES                    ║
    ╚══════════════════════════════════════════════════════════════╝

    COMANDOS PRINCIPALES:
      /teams                  → Lista todos los equipos registrados
      /join <equipo>          → Únete a un equipo
      /project <equipo>       → Muestra el proyecto de un equipo
      /chat <equipo>          → Abre el chat de un equipo
      /help                   → Muestra esta ayuda
      /quit                   → Sale de la aplicación

    EJEMPLOS:
      /teams
      /join Code Masters
      /project Code Masters
      /chat Code Masters

    ══════════════════════════════════════════════════════════════
    """)
  end

  defp listar_equipos do
    equipos = EquipoService.listar_equipos_activos()

    if Enum.empty?(equipos) do
      IO.puts("\n📭 No hay equipos registrados.\n")
    else
      IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
      IO.puts("║                    🏆 EQUIPOS REGISTRADOS                    ║")
      IO.puts("╚══════════════════════════════════════════════════════════════╝\n")

      Enum.each(equipos, fn equipo ->
        miembros = length(equipo.miembros)
        IO.puts("📋 #{equipo.nombre}")
        IO.puts("   ID: #{equipo.id}")
        IO.puts("   Categoría: #{equipo.categoria}")
        IO.puts("   Miembros: #{miembros}")
        IO.puts("   Estado: ✅ Activo")
        IO.puts(String.duplicate("─", 60))
      end)

      IO.puts("")
    end
  end

  defp unirse_equipo(nombre_equipo, usuario) do
    # Buscar si el usuario ya existe como participante
    participante = Enum.find(ETSRepo.listar_participantes(), fn p ->
      p.nombre == usuario.name
    end)

    participante_id = if participante do
      participante.id
    else
      # Crear nuevo participante
      nuevo = Domain.Participante.nuevo(usuario.name, "#{usuario.name}@hackathon.com")
      ETSRepo.guardar_participante(nuevo)
      nuevo.id
    end

    case EquipoService.unir_participante(nombre_equipo, participante_id) do
      {:ok, _equipo} ->
        IO.puts("\n✅ Te has unido exitosamente al equipo '#{nombre_equipo}'!\n")

      {:error, :no_encontrado} ->
        IO.puts("\n❌ No existe un equipo con el nombre '#{nombre_equipo}'.\n")

      {:error, :ya_es_miembro} ->
        IO.puts("\n⚠️  Ya eres miembro del equipo '#{nombre_equipo}'.\n")

      {:error, razon} ->
        IO.puts("\n❌ Error: #{inspect(razon)}\n")
    end
  end

  defp ver_proyecto(nombre_equipo) do
    case ProyectoService.info_completa(nombre_equipo) do
      nil ->
        IO.puts("\n📭 El equipo '#{nombre_equipo}' no tiene un proyecto registrado.\n")

      info ->
        proyecto = info.proyecto
        progreso = info.progreso

        IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
        IO.puts("║              📌 PROYECTO DEL EQUIPO #{String.pad_trailing(nombre_equipo, 23)} ║")
        IO.puts("╚══════════════════════════════════════════════════════════════╝\n")
        IO.puts("Nombre:      #{proyecto.nombre}")
        IO.puts("Categoría:   #{proyecto.categoria}")
        IO.puts("Descripción: #{proyecto.descripcion}")
        IO.puts("Estado:      #{proyecto.estado}")
        IO.puts("Progreso:    #{progreso}%")

        if not Enum.empty?(proyecto.avances) do
          IO.puts("\n--- ÚLTIMOS AVANCES ---")
          proyecto.avances
          |> Enum.take(3)
          |> Enum.each(fn avance ->
            fecha = Domain.Mensaje.formatear_fecha(avance.fecha)
            IO.puts("  • [#{fecha}] #{avance.mensaje}")
          end)
        end

        IO.puts("")
    end
  end

  defp abrir_chat(nombre_equipo, usuario) do
    case EquipoService.obtener_por_nombre(nombre_equipo) do
      nil ->
        IO.puts("\n❌ No existe un equipo con el nombre '#{nombre_equipo}'.\n")

      _equipo ->
        # Buscar participante
        participante = Enum.find(ETSRepo.listar_participantes(), fn p ->
          p.nombre == usuario.name
        end)

        participante_id = if participante do
          participante.id
        else
          nuevo = Domain.Participante.nuevo(usuario.name, "#{usuario.name}@hackathon.com")
          ETSRepo.guardar_participante(nuevo)
          nuevo.id
        end

        # Mostrar historial
        historial = ChatService.historial_equipo(nombre_equipo, 20)

        IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
        IO.puts("║           💬 CHAT DEL EQUIPO #{String.pad_trailing(nombre_equipo, 28)} ║")
        IO.puts("╚══════════════════════════════════════════════════════════════╝\n")

        if Enum.empty?(historial) do
          IO.puts("📭 No hay mensajes aún. ¡Sé el primero en escribir!\n")
        else
          Enum.each(historial, fn msg ->
            remitente = ETSRepo.obtener_participante(msg.remitente_id)
            nombre_remitente = if remitente, do: remitente.nombre, else: "Usuario"
            fecha = Domain.Mensaje.formatear_fecha(msg.fecha_hora)
            IO.puts("[#{fecha}] #{nombre_remitente}: #{msg.contenido}")
          end)
          IO.puts("")
        end

        IO.puts("Escribe tu mensaje (o /exit para salir):\n")
        chat_loop(nombre_equipo, participante_id)
    end
  end

  defp chat_loop(nombre_equipo, participante_id) do
    case IO.gets("> ") |> String.trim() do
      "/exit" ->
        IO.puts("\n👋 Saliendo del chat...\n")
        :ok

      "" ->
        chat_loop(nombre_equipo, participante_id)

      contenido ->
        case ChatService.enviar_mensaje_equipo(nombre_equipo, participante_id, contenido) do
          {:ok, mensaje} ->
            remitente = ETSRepo.obtener_participante(mensaje.remitente_id)
            nombre_remitente = if remitente, do: remitente.nombre, else: "Usuario"
            fecha = Domain.Mensaje.formatear_fecha(mensaje.fecha_hora)
            IO.puts("[#{fecha}] #{nombre_remitente}: #{mensaje.contenido}")
            chat_loop(nombre_equipo, participante_id)

          {:error, razon} ->
            IO.puts("❌ Error: #{inspect(razon)}")
            chat_loop(nombre_equipo, participante_id)
        end
    end
  end

  defp salir do
    IO.puts("\n👋 ¡Gracias por participar en Code4Future! Hasta pronto.\n")
    System.halt(0)
  end

  defp comando_invalido(comando) do
    IO.puts("\n❌ Comando no reconocido: '#{comando}'")
    IO.puts("   Escribe /help para ver los comandos disponibles.\n")
  end
end
