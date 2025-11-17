# Adapters/CLI/interface.ex
defmodule Adapters.CLI.Interface do
  @moduledoc """
  Interfaz principal del CLI
  Maneja el loop de entrada del usuario
  """

  alias Adapters.CLI.CommandHandler
  alias Adapters.Persistence.ETSRepo

  @welcome """
  ╔══════════════════════════════════════════════════════════════╗
  ║                                                              ║
  ║              🚀 HACKATHON CODE4FUTURE 2025 🚀                ║
  ║                                                              ║
  ║  Sistema de Gestión de Hackathon Colaborativa               ║
  ║  Desarrollado en Elixir con Arquitectura Hexagonal          ║
  ║                                                              ║
  ║  Características:                                            ║
  ║    ✅ Gestión de equipos y participantes                    ║
  ║    ✅ Sistema de proyectos con seguimiento                  ║
  ║    ✅ Chat en tiempo real por equipo                        ║
  ║    ✅ Canal de consultas con mentores                       ║
  ║    ✅ Anuncios y salas temáticas                            ║
  ║                                                              ║
  ║  Escribe /help para ver los comandos disponibles            ║
  ║  Escribe /quit para salir                                   ║
  ║                                                              ║
  ╚══════════════════════════════════════════════════════════════╝
  """

  @doc "Inicia la aplicación CLI"
  def start do
    IO.puts(@welcome)

    # Iniciar el repositorio ETS
    {:ok, _pid} = ETSRepo.start_link()

    # Cargar datos de ejemplo
    cargar_datos_ejemplo()

    # Usuario por defecto (en producción sería login)
    usuario = %{id: "admin_1", name: "Organizador"}

    IO.puts("\n👤 Bienvenido, #{usuario.name}!\n")

    # Iniciar loop principal
    loop(usuario)
  end

  # Loop principal de comandos
  defp loop(usuario) do
    comando = IO.gets("hackathon> ") |> String.trim()

    case comando do
      "/quit" ->
        CommandHandler.handle("/quit", usuario)

      _ ->
        CommandHandler.handle(comando, usuario)
        loop(usuario)
    end
  end

  # Carga datos de ejemplo para demostración
  defp cargar_datos_ejemplo do
    IO.puts("\n📦 Cargando datos de ejemplo...")

    # Crear participantes
    participantes = [
      Domain.Participante.nuevo("Ana García", "ana@hackathon.com"),
      Domain.Participante.nuevo("Carlos López", "carlos@hackathon.com"),
      Domain.Participante.nuevo("María Rodríguez", "maria@hackathon.com"),
      Domain.Participante.nuevo("Juan Pérez", "juan@hackathon.com"),
      Domain.Participante.nuevo("Laura Martínez", "laura@hackathon.com")
    ]

    Enum.each(participantes, &ETSRepo.guardar_participante/1)

    # Crear equipos
    {:ok, equipo1} = Services.EquipoService.crear_equipo("Code Masters", "Desarrollo Web")
    {:ok, equipo2} = Services.EquipoService.crear_equipo("Data Wizards", "Machine Learning")
    {:ok, equipo3} = Services.EquipoService.crear_equipo("Mobile Heroes", "Apps Móviles")

    # Asignar miembros a equipos
    Services.EquipoService.unir_participante("Code Masters", Enum.at(participantes, 0).id)
    Services.EquipoService.unir_participante("Code Masters", Enum.at(participantes, 1).id)
    Services.EquipoService.unir_participante("Data Wizards", Enum.at(participantes, 2).id)
    Services.EquipoService.unir_participante("Data Wizards", Enum.at(participantes, 3).id)
    Services.EquipoService.unir_participante("Mobile Heroes", Enum.at(participantes, 4).id)

    # Crear proyectos
    Services.ProyectoService.crear_proyecto(
      "Code Masters",
      "Plataforma Educativa Online",
      "Sistema web para aprendizaje colaborativo",
      "Educación"
    )

    Services.ProyectoService.crear_proyecto(
      "Data Wizards",
      "Predictor de Clima",
      "ML para predicción meteorológica con datos históricos",
      "Inteligencia Artificial"
    )

    Services.ProyectoService.crear_proyecto(
      "Mobile Heroes",
      "App de Reciclaje",
      "Aplicación móvil para promover el reciclaje urbano",
      "Medio Ambiente"
    )

    # Agregar avances
    Services.ProyectoService.actualizar_avance("Code Masters", "Definición de arquitectura completada")
    Services.ProyectoService.actualizar_avance("Code Masters", "Mockups de UI listos")
    Services.ProyectoService.actualizar_avance("Data Wizards", "Dataset recopilado y limpiado")
    Services.ProyectoService.actualizar_avance("Mobile Heroes", "Prototipo inicial funcional")

    # Crear mentores
    Services.MentorService.registrar_mentor(
      "Dr. Roberto Sánchez",
      "roberto@mentor.com",
      ["Backend", "Bases de Datos", "Arquitectura"]
    )

    Services.MentorService.registrar_mentor(
      "Dra. Patricia Gómez",
      "patricia@mentor.com",
      ["Machine Learning", "Python", "Data Science"]
    )

    Services.MentorService.registrar_mentor(
      "Ing. Miguel Torres",
      "miguel@mentor.com",
      ["Mobile Development", "UX/UI", "React Native"]
    )

    # Crear salas temáticas
    Services.ChatService.crear_sala("Backend", "Discusión sobre desarrollo backend")
    Services.ChatService.crear_sala("Frontend", "UI/UX y desarrollo frontend")
    Services.ChatService.crear_sala("DevOps", "Infraestructura y despliegue")

    IO.puts("✅ Datos cargados: 5 participantes, 3 equipos, 3 proyectos, 3 mentores")
    IO.puts("")
  end
end
