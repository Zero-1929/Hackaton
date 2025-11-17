# Adapters/CLI/command_handler.ex
defmodule Adapters.CLI.CommandHandler do
  @moduledoc """
  Manejador de comandos del CLI
  Procesa los comandos ingresados por el usuario
  """

  alias Services.{EquipoService, ProyectoService, ChatService, MentorService}
  alias Adapters.Persistence.ETSRepo
  alias Domain.Participante

  @doc "Procesa un comando ingresado por el usuario"
  def handle(comando, usuario) do
    case String.split(comando, " ", parts: 2) do
      ["/help"] -> mostrar_ayuda()
      ["/teams"] -> listar_equipos()
      ["/join", nombre_equipo] -> unirse_equipo(nombre_equipo, usuario)
      ["/project", nombre_equipo] -> ver_proyecto(nombre_equipo)
      ["/chat", nombre_equipo] -> abrir_chat(nombre_equipo, usuario)
      ["/create-team"] -> crear_equipo_interactivo()
      ["/create-user"] -> crear_usuario_interactivo()
      ["/create-project"] -> crear_proyecto_interactivo(usuario)
      ["/mentors"] -> listar_mentores()
      ["/rooms"] -> listar_salas()
      ["/announce"] -> enviar_anuncio(usuario)
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

    GESTIÓN DE EQUIPOS:
      /teams                  → Lista todos los equipos registrados
      /create-team            → Crea un nuevo equipo
      /join <equipo>          → Únete a un equipo existente

    GESTIÓN DE USUARIOS:
      /create-user            → Registra un nuevo participante

    GESTIÓN DE PROYECTOS:
      /project <equipo>       → Muestra el proyecto de un equipo
      /create-project         → Crea un proyecto para tu equipo

    COMUNICACIÓN:
      /chat <equipo>          → Abre el chat de un equipo
      /announce               → Envía un anuncio general
      /rooms                  → Lista las salas temáticas

    MENTORÍA:
      /mentors                → Lista los mentores disponibles

    SISTEMA:
      /help                   → Muestra esta ayuda
      /quit                   → Sale de la aplicación

    EJEMPLOS:
      /teams
      /create-team
      /join Code Masters
      /project Code Masters
      /chat Code Masters

    ══════════════════════════════════════════════════════════════
    """)
  end

  defp listar_equipos do
    equipos = EquipoService.listar_equipos_activos()

    if Enum.empty?(equipos) do
      IO.puts("\n🔭 No hay equipos registrados.\n")
    else
      IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
      IO.puts("║                    🏆 EQUIPOS REGISTRADOS                    ║")
      IO.puts("╚══════════════════════════════════════════════════════════════\n")

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

  defp crear_equipo_interactivo do
    IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
    IO.puts("║                   🎯 CREAR NUEVO EQUIPO                      ║")
    IO.puts("╚══════════════════════════════════════════════════════════════\n")

    nombre = obtener_input("Nombre del equipo: ")

    if String.trim(nombre) == "" do
      IO.puts("\n❌ El nombre del equipo no puede estar vacío.\n")
    else
      IO.puts("\n📂 Categorías disponibles:")
      IO.puts("   1. Desarrollo Web")
      IO.puts("   2. Machine Learning")
      IO.puts("   3. Apps Móviles")
      IO.puts("   4. Inteligencia Artificial")
      IO.puts("   5. Medio Ambiente")
      IO.puts("   6. Educación")
      IO.puts("   7. Salud")
      IO.puts("   8. Fintech")
      IO.puts("   9. IoT")
      IO.puts("   10. Otra\n")

      opcion = obtener_input("Selecciona una categoría (1-10): ")

      categoria = case opcion do
        "1" -> "Desarrollo Web"
        "2" -> "Machine Learning"
        "3" -> "Apps Móviles"
        "4" -> "Inteligencia Artificial"
        "5" -> "Medio Ambiente"
        "6" -> "Educación"
        "7" -> "Salud"
        "8" -> "Fintech"
        "9" -> "IoT"
        "10" -> obtener_input("Ingresa la categoría: ")
        _ -> "General"
      end

      case EquipoService.crear_equipo(nombre, categoria) do
        {:ok, equipo} ->
          IO.puts("\n✅ ¡Equipo '#{equipo.nombre}' creado exitosamente!")
          IO.puts("   ID: #{equipo.id}")
          IO.puts("   Categoría: #{equipo.categoria}")
          IO.puts("   Ahora puedes unirte con: /join #{equipo.nombre}\n")

        {:error, :equipo_ya_existe} ->
          IO.puts("\n⚠️  Ya existe un equipo con el nombre '#{nombre}'.\n")

        {:error, razon} ->
          IO.puts("\n❌ Error al crear equipo: #{inspect(razon)}\n")
      end
    end
  end

  defp crear_usuario_interactivo do
    IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
    IO.puts("║                  👤 REGISTRAR PARTICIPANTE                   ║")
    IO.puts("╚══════════════════════════════════════════════════════════════\n")

    nombre = obtener_input("Nombre completo: ")
    email = obtener_input("Correo electrónico: ")

    if String.trim(nombre) == "" or String.trim(email) == "" do
      IO.puts("\n❌ El nombre y el correo son obligatorios.\n")
    else
      nuevo_participante = Participante.nuevo(nombre, email)

      if Participante.valido?(nuevo_participante) do
        ETSRepo.guardar_participante(nuevo_participante)
        IO.puts("\n✅ ¡Participante registrado exitosamente!")
        IO.puts("   ID: #{nuevo_participante.id}")
        IO.puts("   Nombre: #{nuevo_participante.nombre}")
        IO.puts("   Email: #{nuevo_participante.email}")
        IO.puts("   Ahora puedes unirte a un equipo con: /join <nombre_equipo>\n")
      else
        IO.puts("\n❌ Los datos ingresados no son válidos. Verifica el formato del email.\n")
      end
    end
  end

  defp crear_proyecto_interactivo(usuario) do
    IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
    IO.puts("║                   📌 CREAR NUEVO PROYECTO                    ║")
    IO.puts("╚══════════════════════════════════════════════════════════════\n")

    # Verificar que el usuario esté en un equipo
    participante = Enum.find(ETSRepo.listar_participantes(), fn p ->
      p.nombre == usuario.name
    end)

    if is_nil(participante) or is_nil(participante.equipo_id) do
      IO.puts("❌ Debes unirte a un equipo antes de crear un proyecto.")
      IO.puts("   Usa: /join <nombre_equipo>\n")
    else
      equipo = ETSRepo.obtener_equipo(participante.equipo_id)

      if equipo.proyecto_id do
        IO.puts("⚠️  Tu equipo '#{equipo.nombre}' ya tiene un proyecto registrado.\n")
      else
        nombre_proyecto = obtener_input("Nombre del proyecto: ")
        descripcion = obtener_input("Descripción del proyecto: ")

        IO.puts("\n📂 Categorías disponibles:")
        IO.puts("   1. Inteligencia Artificial")
        IO.puts("   2. Educación")
        IO.puts("   3. Medio Ambiente")
        IO.puts("   4. Salud")
        IO.puts("   5. Fintech")
        IO.puts("   6. IoT")
        IO.puts("   7. Desarrollo Web")
        IO.puts("   8. Apps Móviles")
        IO.puts("   9. Otra\n")

        opcion = obtener_input("Selecciona una categoría (1-9): ")

        categoria = case opcion do
          "1" -> "Inteligencia Artificial"
          "2" -> "Educación"
          "3" -> "Medio Ambiente"
          "4" -> "Salud"
          "5" -> "Fintech"
          "6" -> "IoT"
          "7" -> "Desarrollo Web"
          "8" -> "Apps Móviles"
          "9" -> obtener_input("Ingresa la categoría: ")
          _ -> "General"
        end

        if String.trim(nombre_proyecto) == "" or String.trim(descripcion) == "" do
          IO.puts("\n❌ El nombre y la descripción son obligatorios.\n")
        else
          case ProyectoService.crear_proyecto(equipo.nombre, nombre_proyecto, descripcion, categoria) do
            {:ok, proyecto} ->
              IO.puts("\n✅ ¡Proyecto creado exitosamente!")
              IO.puts("   ID: #{proyecto.id}")
              IO.puts("   Nombre: #{proyecto.nombre}")
              IO.puts("   Categoría: #{proyecto.categoria}")
              IO.puts("   Equipo: #{equipo.nombre}")
              IO.puts("   Estado: #{proyecto.estado}")
              IO.puts("\n   Puedes ver tu proyecto con: /project #{equipo.nombre}\n")

            {:error, razon} ->
              IO.puts("\n❌ Error al crear proyecto: #{inspect(razon)}\n")
          end
        end
      end
    end
  end

  defp listar_mentores do
    mentores = MentorService.listar_disponibles()

    if Enum.empty?(mentores) do
      IO.puts("\n🔭 No hay mentores disponibles en este momento.\n")
    else
      IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
      IO.puts("║                    👨‍🏫 MENTORES DISPONIBLES                    ║")
      IO.puts("╚══════════════════════════════════════════════════════════════\n")

      Enum.each(mentores, fn mentor ->
        IO.puts("👤 #{mentor.nombre}")
        IO.puts("   ID: #{mentor.id}")
        IO.puts("   Email: #{mentor.email}")
        IO.puts("   Especialidades: #{Enum.join(mentor.especialidades, ", ")}")
        IO.puts("   Estado: ✅ Disponible")
        IO.puts(String.duplicate("─", 60))
      end)

      IO.puts("")
    end
  end

  defp listar_salas do
    salas = ChatService.listar_salas()

    if Enum.empty?(salas) do
      IO.puts("\n🔭 No hay salas temáticas creadas.\n")
    else
      IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
      IO.puts("║                   💬 SALAS TEMÁTICAS                         ║")
      IO.puts("╚══════════════════════════════════════════════════════════════\n")

      Enum.each(salas, fn sala ->
        IO.puts("🚪 #{sala.nombre}")
        IO.puts("   ID: #{sala.id}")
        IO.puts("   Descripción: #{sala.descripcion}")
        IO.puts(String.duplicate("─", 60))
      end)

      IO.puts("")
    end
  end

  defp enviar_anuncio(usuario) do
    IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
    IO.puts("║                    📢 ENVIAR ANUNCIO GENERAL                 ║")
    IO.puts("╚══════════════════════════════════════════════════════════════\n")

    contenido = obtener_input("Mensaje del anuncio: ")

    if String.trim(contenido) == "" do
      IO.puts("\n❌ El mensaje no puede estar vacío.\n")
    else
      participante = Enum.find(ETSRepo.listar_participantes(), fn p ->
        p.nombre == usuario.name
      end)

      remitente_id = if participante, do: participante.id, else: "SYSTEM"

      case ChatService.enviar_anuncio(remitente_id, contenido) do
        {:ok, _mensaje} ->
          IO.puts("\n✅ Anuncio enviado exitosamente.\n")

        {:error, razon} ->
          IO.puts("\n❌ Error al enviar anuncio: #{inspect(razon)}\n")
      end
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
      nuevo = Participante.nuevo(usuario.name, "#{usuario.name}@hackathon.com")
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
        IO.puts("\n🔭 El equipo '#{nombre_equipo}' no tiene un proyecto registrado.\n")

      info ->
        proyecto = info.proyecto
        progreso = info.progreso

        IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
        IO.puts("║              📌 PROYECTO DEL EQUIPO #{String.pad_trailing(nombre_equipo, 23)} ║")
        IO.puts("╚══════════════════════════════════════════════════════════════\n")
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
          nuevo = Participante.nuevo(usuario.name, "#{usuario.name}@hackathon.com")
          ETSRepo.guardar_participante(nuevo)
          nuevo.id
        end

        # Mostrar historial
        historial = ChatService.historial_equipo(nombre_equipo, 20)

        IO.puts("\n╔══════════════════════════════════════════════════════════════╗")
        IO.puts("║           💬 CHAT DEL EQUIPO #{String.pad_trailing(nombre_equipo, 28)} ║")
        IO.puts("╚══════════════════════════════════════════════════════════════\n")

        if Enum.empty?(historial) do
          IO.puts("🔭 No hay mensajes aún. ¡Sé el primero en escribir!\n")
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

  # ============================================================================
  # Funciones auxiliares
  # ============================================================================

  defp obtener_input(prompt) do
    IO.gets(prompt) |> String.trim()
  end
end
