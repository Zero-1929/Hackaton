defmodule Services.ChatService do
  @moduledoc """
  Servicio para gestión de chats en tiempo real
  """

  alias Services.TeamService
  alias Domain.Chat
  alias Domain.Value_objects.{ID_equipo, ID_participante}
  alias Adapters.Persistence.ETSRepo

  @doc """
  Abre el chat de un equipo
  """
  def open_chat(repo, team_name, user) do
    case TeamService.get_team_by_name(repo, team_name) do
      nil ->
        IO.puts("❌ No existe un equipo con ese nombre.\n")
        {:error, :team_not_found}

      team ->
        # Convertir IDs a value objects del Domain
        equipo_id = %ID_equipo{valor: team.id}
        participante_id = %ID_participante{valor: user.id}

        # Suscribir al participante al chat del equipo
        Chat.suscribir_participante(participante_id, equipo_id, [])

        # Obtener historial de mensajes
        case Chat.obtener_historial(:equipo, equipo_id, 50) do
          {:ok, mensajes} ->
            IO.puts("💬 Chat del equipo #{team_name}:")
            IO.puts("=================================")

            if Enum.empty?(mensajes) do
              IO.puts("No hay mensajes aún. ¡Sé el primero en escribir!")
            else
              Enum.each(mensajes, fn mensaje ->
                remitente_data = ETSRepo.get_participant(mensaje.remitente_id.valor)
                mensaje_formateado = Chat.formatear_mensaje(mensaje, remitente_data || %{nombre: "Usuario"})
                IO.puts("[#{mensaje_formateado.fecha_hora}] #{mensaje_formateado.remitente}: #{mensaje_formateado.contenido}")
              end)
            end

            IO.puts("=================================")
            IO.puts("Escribe tu mensaje (o /exit para salir):")
            enter_chat_mode(repo, equipo_id, participante_id, user)

          {:error, reason} ->
            IO.puts("❌ Error al cargar el historial: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  defp enter_chat_mode(repo, equipo_id, participante_id, user) do
    case IO.gets("> ") |> String.trim() do
      "/exit" ->
        IO.puts("Saliendo del chat...\n")
        :ok

      mensaje when byte_size(mensaje) > 0 ->
        # Enviar mensaje usando el Domain
        mensaje_id = Domain.Value_objects.ID_mensaje.generar()

        case Chat.enviar_mensaje_equipo(mensaje_id, mensaje, participante_id, equipo_id) do
          {:ok, _} ->
            enter_chat_mode(repo, equipo_id, participante_id, user)

          {:error, reason} ->
            IO.puts("❌ Error al enviar mensaje: #{inspect(reason)}")
            enter_chat_mode(repo, equipo_id, participante_id, user)
        end

      _ ->
        enter_chat_mode(repo, equipo_id, participante_id, user)
    end
  end

  @doc """
  Envía un anuncio general (solo para organizadores)
  """
  def send_announcement(_repo, user, content) do
    participante_id = %ID_participante{valor: user.id}
    mensaje_id = Domain.Value_objects.ID_mensaje.generar()

    case Chat.enviar_anuncio(mensaje_id, content, participante_id) do
      {:ok, _} ->
        IO.puts("✅ Anuncio enviado a todos los participantes")
        {:ok, :announcement_sent}
      {:error, reason} ->
        IO.puts("❌ Error al enviar anuncio: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Obtiene el historial de anuncios
  """
  def get_announcements(_repo, limit \\ 20) do
    case Chat.obtener_historial(:anuncio, nil, limit) do
      {:ok, mensajes} ->
        mensajes_formateados = Enum.map(mensajes, fn mensaje ->
          remitente_data = ETSRepo.get_participant(mensaje.remitente_id.valor)
          Chat.formatear_mensaje(mensaje, remitente_data || %{nombre: "Organizador"})
        end)
        {:ok, mensajes_formateados}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
