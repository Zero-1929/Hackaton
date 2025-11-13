defmodule Services.MentorService do
  @moduledoc """
  Servicio para gestión de mentores y retroalimentación
  """

  alias Domain.Mentor
  alias Adapters.Persistence.RepoBehavior

  @doc """
  Registra un nuevo mentor en el sistema
  """
  def register_mentor(repo, name, email, expertise) do
    mentor = Mentor.registrar(name, email, String.split(expertise, ","))

    mentor_data = %{
      id: mentor.id,
      nombre: mentor.nombre,
      email: mentor.email,
      especialidades: mentor.especialidades,
      disponible: mentor.disponible,
      consultas_pendientes: mentor.consultas_pendientes,
      consultas_respondidas: mentor.consultas_respondidas,
      feedback_dado: mentor.feedback_dado
    }

    RepoBehavior.save_mentor(repo, mentor_data)
    {:ok, mentor_data}
  end

  @doc """
  Lista todos los mentores registrados
  """
  def list_mentors(repo) do
    RepoBehavior.list_mentors(repo)
  end

  @doc """
  Registra una consulta de un equipo a un mentor
  """
  def register_consultation(repo, mentor_id, team_id, project_id, message) do
    case RepoBehavior.get_mentor(repo, mentor_id) do
      nil ->
        {:error, "Mentor no encontrado"}

      mentor_data ->
        mentor = struct(Mentor, mentor_data)

        case Mentor.registrar_consulta(mentor, team_id, project_id, message) do
          {:ok, mentor_actualizado} ->
            updated_mentor_data = %{
              mentor_data |
              consultas_pendientes: mentor_actualizado.consultas_pendientes
            }
            RepoBehavior.save_mentor(repo, updated_mentor_data)
            {:ok, "Consulta registrada exitosamente"}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Responde a una consulta pendiente
  """
  def respond_consultation(repo, mentor_id, consultation_id, response) do
    case RepoBehavior.get_mentor(repo, mentor_id) do
      nil ->
        {:error, "Mentor no encontrado"}

      mentor_data ->
        mentor = struct(Mentor, mentor_data)

        case Mentor.responder_consulta(mentor, consultation_id, response) do
          {:ok, mentor_actualizado} ->
            updated_mentor_data = %{
              mentor_data |
              consultas_pendientes: mentor_actualizado.consultas_pendientes,
              consultas_respondidas: mentor_actualizado.consultas_respondidas,
              feedback_dado: mentor_actualizado.feedback_dado
            }
            RepoBehavior.save_mentor(repo, updated_mentor_data)
            {:ok, "Consulta respondida exitosamente"}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Agrega feedback directo a un proyecto
  """
  def add_feedback(repo, mentor_id, project_id, message, suggestions \\ [], rating \\ nil) do
    case RepoBehavior.get_mentor(repo, mentor_id) do
      nil ->
        {:error, "Mentor no encontrado"}

      mentor_data ->
        mentor = struct(Mentor, mentor_data)

        case Mentor.agregar_feedback(mentor, project_id, message, suggestions, rating) do
          {:ok, mentor_actualizado} ->
            updated_mentor_data = %{
              mentor_data |
              feedback_dado: mentor_actualizado.feedback_dado
            }
            RepoBehavior.save_mentor(repo, updated_mentor_data)
            {:ok, "Feedback agregado exitosamente"}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Obtiene las consultas pendientes de un mentor
  """
  def get_pending_consultations(repo, mentor_id) do
    case RepoBehavior.get_mentor(repo, mentor_id) do
      nil -> {:error, "Mentor no encontrado"}
      mentor_data ->
        mentor = struct(Mentor, mentor_data)
        {:ok, Mentor.obtener_consultas_pendientes(mentor)}
    end
  end

  @doc """
  Cambia la disponibilidad de un mentor
  """
  def set_availability(repo, mentor_id, available) do
    case RepoBehavior.get_mentor(repo, mentor_id) do
      nil ->
        {:error, "Mentor no encontrado"}

      mentor_data ->
        mentor = struct(Mentor, mentor_data)
        mentor_actualizado = Mentor.cambiar_disponibilidad(mentor, available)

        updated_mentor_data = %{mentor_data | disponible: mentor_actualizado.disponible}
        RepoBehavior.save_mentor(repo, updated_mentor_data)

        status = if available, do: "disponible", else: "no disponible"
        {:ok, "Mentor marcado como #{status}"}
    end
  end
end
