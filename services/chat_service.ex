defmodule Services.ChatService do
  @moduledoc """
  Servicio de aplicación encargado de gestionar la mensajería del sistema.

  Incluye:
  - Envío de mensajes a equipos, salas temáticas, mentores y anuncios globales.
  - Obtención de historiales de mensajes.
  - Creación y listado de salas temáticas.

  Este servicio actúa como capa de orquestación entre el Dominio (`Domain.Mensaje`)
  y la capa de persistencia (`ETSRepo`).
  """

  alias Domain.Mensaje
  alias Adapters.Persistence.ETSRepo
  alias Services.EquipoService

  # ENVÍO DE MENSAJES

  @doc """
  Envía un mensaje al chat de un equipo.

  ## Parámetros
  - `nombre_equipo` — Nombre del equipo destino.
  - `remitente_id` — Identificador del usuario que envía el mensaje.
  - `contenido` — Texto del mensaje.

  ## Retorno
  - `{:ok, Mensaje}` si el mensaje es válido y se guarda correctamente.
  - `{:error, :equipo_no_encontrado}` si el equipo no existe.
  - `{:error, :mensaje_invalido}` si el mensaje no cumple las reglas del dominio.
  """
  @spec enviar_mensaje_equipo(String.t(), String.t(), String.t()) ::
          {:ok, Mensaje.t()} | {:error, atom()}
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

  @doc """
  Envía un anuncio general visible para todos.

  ## Parámetros
  - `remitente_id` — Usuario que emite el anuncio.
  - `contenido` — Texto del anuncio.

  ## Retorno
  Igual que en `enviar_mensaje_equipo/3`.
  """
  @spec enviar_anuncio(String.t(), String.t()) ::
          {:ok, Mensaje.t()} | {:error, atom()}
  def enviar_anuncio(remitente_id, contenido) do
    mensaje = Mensaje.anuncio(remitente_id, contenido)

    if Mensaje.valido?(mensaje) do
      ETSRepo.guardar_mensaje(mensaje)
      {:ok, mensaje}
    else
      {:error, :mensaje_invalido}
    end
  end

  @doc """
  Envía un mensaje a una sala temática.

  ## Parámetros
  - `sala_id` — Identificador de la sala temática.
  - `remitente_id` — Usuario que envía.
  - `contenido` — Texto del mensaje.

  ## Retorno
  - `{:error, :sala_no_encontrada}` si la sala no existe.
  - Restos de respuestas iguales a los otros métodos.
  """
  @spec enviar_mensaje_sala(String.t(), String.t(), String.t()) ::
          {:ok, Mensaje.t()} | {:error, atom()}
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

  @doc """
  Envía un mensaje dirigido a un mentor.

  ## Parámetros
  - `mentor_id` — Identificador del mentor.
  - `remitente_id` — Usuario que envía.
  - `contenido` — Texto del mensaje.

  ## Retorno
  - `{:error, :mentor_no_encontrado}` si el mentor no existe.
  - Respuestas estándar en caso de éxito o mensaje inválido.
  """
  @spec enviar_mensaje_mentor(String.t(), String.t(), String.t()) ::
          {:ok, Mensaje.t()} | {:error, atom()}
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

  # HISTORIALES DE MENSAJES

  @doc """
  Obtiene el historial de mensajes de un equipo.

  ## Parámetros
  - `nombre_equipo` — Nombre del equipo.
  - `limite` — Cantidad máxima de mensajes (por defecto 50).

  ## Retorno
  - Lista de mensajes ordenados del más antiguo al más reciente.
  - Lista vacía si el equipo no existe.
  """
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

  @doc """
  Obtiene el historial global de anuncios del sistema.

  ## Parámetros
  - `limite` — Cantidad de anuncios a recuperar (por defecto 20).
  """
  @spec historial_anuncios(integer()) :: list(Mensaje.t())
  def historial_anuncios(limite \\ 20) do
    ETSRepo.listar_mensajes(:anuncio, nil, limite)
    |> Enum.reverse()
  end

  @doc """
  Obtiene el historial de mensajes de una sala temática.

  ## Parámetros
  - `sala_id` — Identificador de la sala.
  - `limite` — Número máximo de mensajes (por defecto 50).
  """
  @spec historial_sala(String.t(), integer()) :: list(Mensaje.t())
  def historial_sala(sala_id, limite \\ 50) do
    ETSRepo.listar_mensajes(:sala_tematica, sala_id, limite)
    |> Enum.reverse()
  end

  @doc """
  Obtiene el historial de mensajes enviados entre un usuario y un mentor.

  ## Parámetros
  - `mentor_id` — Identificador del mentor.
  - `limite` — Cantidad máxima de mensajes (por defecto 30).
  """
  @spec historial_mentor(String.t(), integer()) :: list(Mensaje.t())
  def historial_mentor(mentor_id, limite \\ 30) do
    ETSRepo.listar_mensajes(:mentor, mentor_id, limite)
    |> Enum.reverse()
  end

  # GESTIÓN DE SALAS TEMÁTICAS

  @doc """
  Crea una nueva sala temática.

  Genera un identificador único basado en:
  - Timestamp actual en milisegundos.
  - Un número aleatorio de 1 a 9999.

  ## Retorno
  - `{:ok, sala_map}` con toda la información de la sala creada.
  """
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

  @doc """
  Lista todas las salas temáticas registradas.
  """
  @spec listar_salas() :: list(map())
  def listar_salas do
    ETSRepo.listar_salas()
  end

  # FUNCIONES PRIVADAS

  @doc false
  # Genera un ID con formato: "SALA-<timestamp>-<random>"
  defp generar_id_sala do
    timestamp = System.system_time(:millisecond)
    random = :rand.uniform(9999)
    "SALA-#{timestamp}-#{random}"
  end
end
