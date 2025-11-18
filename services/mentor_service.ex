# Services/mentor_service.ex
defmodule Services.MentorService do
  @moduledoc """
  Servicio de aplicación para gestión de mentores
  """

  alias Domain.Mentor
  alias Adapters.Persistence.ETSRepo
  alias Services.{EquipoService, ProyectoService}

  @doc "Registra un nuevo mentor"
  @spec registrar_mentor(String.t(), String.t(), list(String.t())) :: {:ok, Mentor.t()}
  def registrar_mentor(nombre, email, especialidades) do
    mentor = Mentor.nuevo(nombre, email, especialidades)
    ETSRepo.guardar_mentor(mentor)
    {:ok, mentor}
  end

  @doc "Lista todos los mentores"
  @spec listar_mentores() :: list(Mentor.t())
  def listar_mentores do
    ETSRepo.listar_mentores()
  end

  @doc "Lista solo mentores disponibles"
  @spec listar_disponibles() :: list(Mentor.t())
  def listar_disponibles do
    ETSRepo.listar_mentores()
    |> Enum.filter(& &1.disponible)
  end

  @doc "Obtiene un mentor por ID"
  @spec obtener_mentor(String.t()) :: Mentor.t() | nil
  def obtener_mentor(id) do
    ETSRepo.obtener_mentor(id)
  end

  @doc "Registra una consulta de un equipo a un mentor"
  @spec registrar_consulta(String.t(), String.t(), String.t()) :: {:ok, Mentor.t()} | {:error, atom()}
  def registrar_consulta(mentor_id, nombre_equipo, mensaje) do
    with %Mentor{} = mentor <- ETSRepo.obtener_mentor(mentor_id),
         info_equipo when not is_nil(info_equipo) <- EquipoService.info_completa(nombre_equipo),
         proyecto when not is_nil(proyecto) <- info_equipo.proyecto do

      case Mentor.registrar_consulta(mentor, info_equipo.equipo.id, proyecto.id, mensaje) do
        {:ok, mentor_actualizado} ->
          ETSRepo.guardar_mentor(mentor_actualizado)
          {:ok, mentor_actualizado}

        error ->
          error
      end
    else
      nil -> {:error, :no_encontrado}
      _ -> {:error, :datos_insuficientes}
    end
  end

  @doc "Responde una consulta"
  @spec responder_consulta(String.t(), String.t(), String.t()) :: {:ok, Mentor.t()} | {:error, atom()}
  def responder_consulta(mentor_id, consulta_id, respuesta) do
    case ETSRepo.obtener_mentor(mentor_id) do
      nil ->
        {:error, :mentor_no_encontrado}

      mentor ->
        case Mentor.responder_consulta(mentor, consulta_id, respuesta) do
          {:ok, mentor_actualizado} ->
            ETSRepo.guardar_mentor(mentor_actualizado)
            {:ok, mentor_actualizado}

          error ->
            error
        end
    end
  end

  @doc "Agrega feedback a un proyecto"
  @spec agregar_feedback(String.t(), String.t(), String.t(), integer() | nil) :: {:ok, Mentor.t()} | {:error, atom()}
  def agregar_feedback(mentor_id, nombre_equipo, mensaje, calificacion \\ nil) do
    with %Mentor{} = mentor <- ETSRepo.obtener_mentor(mentor_id),
         proyecto when not is_nil(proyecto) <- ProyectoService.obtener_por_equipo(nombre_equipo) do

      mentor_actualizado = Mentor.agregar_feedback(mentor, proyecto.id, mensaje, calificacion)
      ETSRepo.guardar_mentor(mentor_actualizado)
      {:ok, mentor_actualizado}
    else
      nil -> {:error, :no_encontrado}
    end
  end

  @doc "Obtiene consultas pendientes de un mentor"
  @spec consultas_pendientes(String.t()) :: list(map()) | {:error, atom()}
  def consultas_pendientes(mentor_id) do
    case ETSRepo.obtener_mentor(mentor_id) do
      nil ->
        {:error, :mentor_no_encontrado}

      mentor ->
        Mentor.consultas_pendientes(mentor)
    end
  end

  @doc "Obtiene feedback de un mentor para un proyecto"
  @spec feedback_proyecto(String.t(), String.t()) :: list(map()) | {:error, atom()}
  def feedback_proyecto(mentor_id, nombre_equipo) do
    with %Mentor{} = mentor <- ETSRepo.obtener_mentor(mentor_id),
         proyecto when not is_nil(proyecto) <- ProyectoService.obtener_por_equipo(nombre_equipo) do

      Mentor.feedback_proyecto(mentor, proyecto.id)
    else
      nil -> {:error, :no_encontrado}
    end
  end

  @doc "Cambia la disponibilidad de un mentor"
  @spec cambiar_disponibilidad(String.t(), boolean()) :: {:ok, Mentor.t()} | {:error, atom()}
  def cambiar_disponibilidad(mentor_id, disponible) do
    case ETSRepo.obtener_mentor(mentor_id) do
      nil ->
        {:error, :mentor_no_encontrado}

      mentor ->
        mentor_actualizado = Mentor.cambiar_disponibilidad(mentor, disponible)
        ETSRepo.guardar_mentor(mentor_actualizado)
        {:ok, mentor_actualizado}
    end
  end
end
