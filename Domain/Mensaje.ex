defmodule Mensaje do
  @moduledoc """
  Módulo para la gestión de mensajes dentro del sistema de Hackathon.
  """

  @enforce_keys [:id, :contenido, :remitente_id, :tipo, :fecha_hora]
  defstruct [
    :id,
    :contenido,
    :remitente_id,
    :tipo,  # :equipo | :anuncio | :sala_tematica
    :fecha_hora,
    equipo_id: nil,
    sala_tematica_id: nil
  ]

  alias __MODULE__
  alias Domain.Value_objects.{ID_equipo, ID_participante}

  # ======================================================
  # Creación de mensajes
  # ======================================================

  @spec nuevo_mensaje_equipo(String.t(), String.t(), ID_participante.t(), ID_equipo.t()) :: Mensaje.t()
  def nuevo_mensaje_equipo(id \\ generar_id(), contenido, %ID_participante{} = remitente_id, %ID_equipo{} = equipo_id) do
    crear_mensaje(:equipo, id, contenido, remitente_id, equipo_id, nil)
  end

  @spec nuevo_anuncio(String.t(), String.t(), ID_participante.t()) :: Mensaje.t()
  def nuevo_anuncio(id \\ generar_id(), contenido, %ID_participante{} = remitente_id) do
    crear_mensaje(:anuncio, id, contenido, remitente_id, nil, nil)
  end

  @spec nuevo_mensaje_sala_tematica(String.t(), String.t(), ID_participante.t(), String.t()) :: Mensaje.t()
  def nuevo_mensaje_sala_tematica(id \\ generar_id(), contenido, %ID_participante{} = remitente_id, sala_tematica_id) do
    crear_mensaje(:sala_tematica, id, contenido, remitente_id, nil, sala_tematica_id)
  end

  # ======================================================
  # Validaciones
  # ======================================================

  @spec valido?(Mensaje.t()) :: boolean()
  def valido?(%Mensaje{contenido: contenido, remitente_id: remitente_id})
      when is_binary(contenido) and byte_size(contenido) > 0 and not is_nil(remitente_id),
      do: true

  def valido?(_), do: false

  # ======================================================
  # Utilidades
  # ======================================================

  @spec formatear_fecha_hora(DateTime.t()) :: String.t()
  def formatear_fecha_hora(%DateTime{} = fecha_hora) do
    fecha_hora
    |> DateTime.shift_zone!("America/Bogota")
    |> Calendar.strftime("%d/%m/%Y %H:%M")
  end

  @spec generar_id() :: String.t()
  defp generar_id do
    uniq = :erlang.unique_integer([:positive, :monotonic])
    "M-" <> Integer.to_string(uniq)
  end

  # ======================================================
  # Privado: Constructor genérico
  # ======================================================

  @spec crear_mensaje(atom(), String.t(), String.t(), ID_participante.t(), ID_equipo.t() | nil, String.t() | nil) ::
          Mensaje.t()
  defp crear_mensaje(tipo, id, contenido, remitente_id, equipo_id, sala_tematica_id) do
    %Mensaje{
      id: id,
      contenido: contenido,
      remitente_id: remitente_id,
      tipo: tipo,
      equipo_id: equipo_id,
      sala_tematica_id: sala_tematica_id,
      fecha_hora: DateTime.utc_now()
    }
  end
end
