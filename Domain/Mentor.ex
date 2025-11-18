# Domain/mentor.ex
defmodule Domain.Mentor do
  @moduledoc """
  Entidad de dominio: Mentor de la Hackathon
  """

  @enforce_keys [:id, :nombre, :email, :especialidades]
  defstruct [
    :id,
    :nombre,
    :email,
    :especialidades,
    disponible: true,
    consultas: [],
    feedback: []
  ]

  @type consulta :: %{
    id: String.t(),
    equipo_id: String.t(),
    proyecto_id: String.t(),
    mensaje: String.t(),
    fecha: DateTime.t(),
    respondida: boolean(),
    respuesta: String.t() | nil
  }

  @type feedback :: %{
    id: String.t(),
    proyecto_id: String.t(),
    mensaje: String.t(),
    fecha: DateTime.t(),
    calificacion: integer() | nil
  }

  @type t :: %__MODULE__{
    id: String.t(),
    nombre: String.t(),
    email: String.t(),
    especialidades: list(String.t()),
    disponible: boolean(),
    consultas: list(consulta()),
    feedback: list(feedback())
  }

  @doc "Crea un nuevo mentor"
  @spec nuevo(String.t(), String.t(), list(String.t())) :: t()
  def nuevo(nombre, email, especialidades) do
    %__MODULE__{
      id: generar_id(),
      nombre: nombre,
      email: email,
      especialidades: especialidades,
      disponible: true,
      consultas: [],
      feedback: []
    }
  end

  @doc "Registra una consulta de un equipo"
  @spec registrar_consulta(t(), String.t(), String.t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def registrar_consulta(%__MODULE__{disponible: false}, _, _, _) do
    {:error, :mentor_no_disponible}
  end

  def registrar_consulta(%__MODULE__{consultas: consultas} = mentor, equipo_id, proyecto_id, mensaje) do
    nueva_consulta = %{
      id: generar_id_consulta(),
      equipo_id: equipo_id,
      proyecto_id: proyecto_id,
      mensaje: mensaje,
      fecha: DateTime.utc_now(),
      respondida: false,
      respuesta: nil
    }

    {:ok, %{mentor | consultas: [nueva_consulta | consultas]}}
  end

  @doc "Responde una consulta"
  @spec responder_consulta(t(), String.t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def responder_consulta(%__MODULE__{consultas: consultas} = mentor, consulta_id, respuesta) do
    case Enum.find_index(consultas, &(&1.id == consulta_id)) do
      nil ->
        {:error, :consulta_no_encontrada}

      index ->
        consultas_actualizadas = List.update_at(consultas, index, fn consulta ->
          %{consulta | respondida: true, respuesta: respuesta}
        end)

        {:ok, %{mentor | consultas: consultas_actualizadas}}
    end
  end

  @doc "Agrega feedback a un proyecto"
  @spec agregar_feedback(t(), String.t(), String.t(), integer() | nil) :: t()
  def agregar_feedback(%__MODULE__{feedback: feedback} = mentor, proyecto_id, mensaje, calificacion \\ nil) do
    nuevo_feedback = %{
      id: generar_id_feedback(),
      proyecto_id: proyecto_id,
      mensaje: mensaje,
      fecha: DateTime.utc_now(),
      calificacion: calificacion
    }

    %{mentor | feedback: [nuevo_feedback | feedback]}
  end

  @doc "Cambia la disponibilidad del mentor"
  @spec cambiar_disponibilidad(t(), boolean()) :: t()
  def cambiar_disponibilidad(%__MODULE__{} = mentor, disponible) do
    %{mentor | disponible: disponible}
  end

  @doc "Obtiene consultas pendientes"
  @spec consultas_pendientes(t()) :: list(consulta())
  def consultas_pendientes(%__MODULE__{consultas: consultas}) do
    Enum.filter(consultas, &(not &1.respondida))
  end

  @doc "Obtiene feedback para un proyecto"
  @spec feedback_proyecto(t(), String.t()) :: list(feedback())
  def feedback_proyecto(%__MODULE__{feedback: feedback}, proyecto_id) do
    Enum.filter(feedback, &(&1.proyecto_id == proyecto_id))
  end

  # Privadas
  defp generar_id do
    timestamp = System.system_time(:millisecond)
    random = :rand.uniform(9999)
    "MTR-#{timestamp}-#{random}"
  end

  defp generar_id_consulta do
    timestamp = System.system_time(:millisecond)
    random = :rand.uniform(9999)
    "CONS-#{timestamp}-#{random}"
  end

  defp generar_id_feedback do
    timestamp = System.system_time(:millisecond)
    random = :rand.uniform(9999)
    "FB-#{timestamp}-#{random}"
  end
end
