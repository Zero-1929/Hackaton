# Domain/mensaje.ex
defmodule Domain.Mensaje do
  @moduledoc """
  Entidad de dominio: Mensaje del sistema de chat
  """

  @enforce_keys [:id, :contenido, :remitente_id, :tipo]
  defstruct [
    :id,
    :contenido,
    :remitente_id,
    :tipo,
    :fecha_hora,
    destino_id: nil
  ]

  @type tipo_mensaje :: :equipo | :anuncio | :sala_tematica | :mentor

  @type t :: %__MODULE__{
    id: String.t(),
    contenido: String.t(),
    remitente_id: String.t(),
    tipo: tipo_mensaje(),
    fecha_hora: DateTime.t(),
    destino_id: String.t() | nil
  }

  @doc "Crea un mensaje de equipo"
  @spec mensaje_equipo(String.t(), String.t(), String.t()) :: t()
  def mensaje_equipo(remitente_id, contenido, equipo_id) do
    %__MODULE__{
      id: generar_id(),
      contenido: contenido,
      remitente_id: remitente_id,
      tipo: :equipo,
      fecha_hora: DateTime.utc_now(),
      destino_id: equipo_id
    }
  end

  @doc "Crea un anuncio general"
  @spec anuncio(String.t(), String.t()) :: t()
  def anuncio(remitente_id, contenido) do
    %__MODULE__{
      id: generar_id(),
      contenido: contenido,
      remitente_id: remitente_id,
      tipo: :anuncio,
      fecha_hora: DateTime.utc_now(),
      destino_id: nil
    }
  end

  @doc "Crea un mensaje de sala temática"
  @spec mensaje_sala(String.t(), String.t(), String.t()) :: t()
  def mensaje_sala(remitente_id, contenido, sala_id) do
    %__MODULE__{
      id: generar_id(),
      contenido: contenido,
      remitente_id: remitente_id,
      tipo: :sala_tematica,
      fecha_hora: DateTime.utc_now(),
      destino_id: sala_id
    }
  end

  @doc "Crea un mensaje para mentor"
  @spec mensaje_mentor(String.t(), String.t(), String.t()) :: t()
  def mensaje_mentor(remitente_id, contenido, mentor_id) do
    %__MODULE__{
      id: generar_id(),
      contenido: contenido,
      remitente_id: remitente_id,
      tipo: :mentor,
      fecha_hora: DateTime.utc_now(),
      destino_id: mentor_id
    }
  end

  @doc "Valida que un mensaje sea correcto"
  @spec valido?(t()) :: boolean()
  def valido?(%__MODULE__{contenido: contenido}) do
    String.trim(contenido) != ""
  end

  @doc "Formatea la fecha del mensaje"
  @spec formatear_fecha(DateTime.t()) :: String.t()
  def formatear_fecha(fecha_hora) do
    fecha_hora
    |> DateTime.shift_zone!("America/Bogota")
    |> Calendar.strftime("%d/%m/%Y %H:%M:%S")
  rescue
    _ -> DateTime.to_string(fecha_hora)
  end

  # Privadas
  defp generar_id do
    timestamp = System.system_time(:millisecond)
    random = :rand.uniform(9999)
    "MSG-#{timestamp}-#{random}"
  end
end
