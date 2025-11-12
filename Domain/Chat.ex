defmodule Domain.Chat do
  @moduledoc """
  Módulo de contexto para la funcionalidad de chat de la Hackathon.
  Proporciona una API de alto nivel para interactuar con el sistema de mensajería.
  """
  
  alias Domain.Mensaje
  alias Domain.Chat.ServidorChat
  alias Domain.Value_objects.{ID_equipo, ID_participante}
  
  @doc """
  Envía un mensaje a un equipo.
  """
  def enviar_mensaje_equipo(id, contenido, %ID_participante{} = remitente_id, %ID_equipo{} = equipo_id) do
    mensaje = Mensaje.nuevo_mensaje_equipo(id, contenido, remitente_id, equipo_id)
    ServidorChat.enviar_mensaje(mensaje)
  end
  
  @doc """
  Envía un anuncio general a todos los participantes.
  Solo disponible para organizadores.
  """
  def enviar_anuncio(id, contenido, %ID_participante{} = remitente_id) do
    mensaje = Mensaje.nuevo_anuncio(id, contenido, remitente_id)
    ServidorChat.enviar_mensaje(mensaje)
  end
  
  @doc """
  Envía un mensaje a una sala temática.
  """
  def enviar_mensaje_sala_tematica(id, contenido, %ID_participante{} = remitente_id, tema_id) do
    mensaje = Mensaje.nuevo_mensaje_sala_tematica(id, contenido, remitente_id, tema_id)
    ServidorChat.enviar_mensaje(mensaje)
  end
  
  @doc """
  Suscribe a un participante a los canales relevantes.
  """
  def suscribir_participante(participante_id, equipo_id, temas_interes) do
    ServidorChat.suscribir_participante(participante_id, equipo_id, temas_interes)
  end
  
  @doc """
  Obtiene el historial de mensajes para un canal específico.
  """
  def obtener_historial(:equipo, equipo_id, limit \\ 100) do
    ServidorChat.obtener_historial(:equipo, equipo_id, limit)
  end
  
  def obtener_historial(:anuncio, _id \\ nil, limit \\ 100) do
    ServidorChat.obtener_historial(:anuncio, nil, limit)
  end
  
  def obtener_historial(:sala_tematica, sala_id, limit \\ 100) do
    ServidorChat.obtener_historial(:sala_tematica, sala_id, limit)
  end
  
  @doc """
  Formatea un mensaje para mostrarlo en la interfaz de usuario.
  """
  def formatear_mensaje(%Mensaje{} = mensaje, remitente) do
    %{
      id: mensaje.id,
      contenido: mensaje.contenido,
      remitente: remitente.nombre,
      remitente_id: mensaje.remitente_id,
      tipo: mensaje.tipo,
      fecha_hora: Mensaje.formatear_fecha_hora(mensaje.fecha_hora),
      es_anuncio: mensaje.tipo == :anuncio
    }
  end
  
  @doc """
  Crea una nueva sala temática.
  """
  def crear_sala_tematica(nombre, descripcion, creador_id) do
    # Implementar la lógica para crear una nueva sala temática
    # y devolver el ID de la sala creada
    {:ok, "sala_#{:crypto.strong_rand_bytes(8) |> Base.url_encode64(padding: false)}"}
  end
  
  @doc """
  Lista las salas temáticas disponibles.
  """
  def listar_salas_tematicas() do
    # Implementar la lógica para listar salas temáticas
    []
  end
end
