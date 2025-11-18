# Services/chat_service.ex
defmodule Services.ChatService do
  @moduledoc """
  Servicio de aplicación para gestión de chat y mensajería
  """

  alias Domain.Mensaje
  alias Adapters.Persistence.ETSRepo
  alias Services.EquipoService

  @doc "Envía un mensaje al chat de un equipo"
  @spec enviar_mensaje_equipo(String.t(), String.t(), String.t()) :: {:ok, Mensaje.t()} | {:error, atom()}
  def enviar_mensaje_equipo(nombre_equipo, remitente_id, contenido) do
    case EquipoService.obtener_por_nombre(nombre_equipo) do
      nil ->
        {:error, :equipo_no_encontrado}

      equipo ->
        mensaje = Mensaje.mensaje_equipo(remitente_id, contenido, equipo.id)

        if Mensaje.valido?(mensaje) do
          ETSRepo.guardar_mensaje(mensaje)
          {:ok, mensaje}
        else
          {:error, :mensaje_invalido}
        end
    end
  end

  @doc "Envía un anuncio general"
  @spec enviar_anuncio(String.t(), String.t()) :: {:ok, Mensaje.t()} | {:error, atom()}
  def enviar_anuncio(remitente_id, contenido) do
    mensaje = Mensaje.anuncio(remitente_id, contenido)

    if Mensaje.valido?(mensaje) do
      ETSRepo.guardar_mensaje(mensaje)
      {:ok, mensaje}
    else
      {:error, :mensaje_invalido}
    end
  end

  @doc "Envía un mensaje a una sala temática"
  @spec enviar_mensaje_sala(String.t(), String.t(), String.t()) :: {:ok, Mensaje.t()} | {:error, atom()}
  def enviar_mensaje_sala(sala_id, remitente_id, contenido) do
    case ETSRepo.obtener_sala(sala_id) do
      nil ->
        {:error, :sala_no_encontrada}

      _sala ->
        mensaje = Mensaje.mensaje_sala(remitente_id, contenido, sala_id)

        if Mensaje.valido?(mensaje) do
          ETSRepo.guardar_mensaje(mensaje)
          {:ok, mensaje}
        else
          {:error, :mensaje_invalido}
        end
    end
  end

  @doc "Envía un mensaje a un mentor"
  @spec enviar_mensaje_mentor(String.t(), String.t(), String.t()) :: {:ok, Mensaje.t()} | {:error, atom()}
  def enviar_mensaje_mentor(mentor_id, remitente_id, contenido) do
    case ETSRepo.obtener_mentor(mentor_id) do
      nil ->
        {:error, :mentor_no_encontrado}

      _mentor ->
        mensaje = Mensaje.mensaje_mentor(remitente_id, contenido, mentor_id)

        if Mensaje.valido?(mensaje) do
          ETSRepo.guardar_mensaje(mensaje)
          {:ok, mensaje}
        else
          {:error, :mensaje_invalido}
        end
    end
  end

  @doc "Obtiene el historial de mensajes de un equipo"
  @spec historial_equipo(String.t(), integer()) :: list(Mensaje.t())
  def historial_equipo(nombre_equipo, limite \\ 50) do
    case EquipoService.obtener_por_nombre(nombre_equipo) do
      nil ->
        []

      equipo ->
        ETSRepo.listar_mensajes(:equipo, equipo.id, limite)
        |> Enum.reverse()
    end
  end

  @doc "Obtiene el historial de anuncios"
  @spec historial_anuncios(integer()) :: list(Mensaje.t())
  def historial_anuncios(limite \\ 20) do
    ETSRepo.listar_mensajes(:anuncio, nil, limite)
    |> Enum.reverse()
  end

  @doc "Obtiene el historial de una sala temática"
  @spec historial_sala(String.t(), integer()) :: list(Mensaje.t())
  def historial_sala(sala_id, limite \\ 50) do
    ETSRepo.listar_mensajes(:sala_tematica, sala_id, limite)
    |> Enum.reverse()
  end

  @doc "Obtiene mensajes con un mentor"
  @spec historial_mentor(String.t(), integer()) :: list(Mensaje.t())
  def historial_mentor(mentor_id, limite \\ 30) do
    ETSRepo.listar_mensajes(:mentor, mentor_id, limite)
    |> Enum.reverse()
  end

  @doc "Crea una sala temática"
  @spec crear_sala(String.t(), String.t()) :: {:ok, map()}
  def crear_sala(nombre, descripcion) do
    sala = %{
      id: generar_id_sala(),
      nombre: nombre,
      descripcion: descripcion,
      fecha_creacion: DateTime.utc_now()
    }

    ETSRepo.guardar_sala(sala)
    {:ok, sala}
  end

  @doc "Lista todas las salas temáticas"
  @spec listar_salas() :: list(map())
  def listar_salas do
    ETSRepo.listar_salas()
  end

  # Privadas
  defp generar_id_sala do
    timestamp = System.system_time(:millisecond)
    random = :rand.uniform(9999)
    "SALA-#{timestamp}-#{random}"
  end
end
