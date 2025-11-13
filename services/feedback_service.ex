defmodule Services.FeedbackService do
  @moduledoc """
  Servicio especializado para gestión de retroalimentación
  """

  alias Services.{TeamService, MentorService}
  alias Adapters.Persistence.RepoBehavior

  @doc """
  Obtiene todo el feedback de un proyecto por nombre de equipo
  """
  def get_project_feedback(repo, team_name) do
    case TeamService.get_team_by_name(repo, team_name) do
      nil ->
        {:error, "Equipo '#{team_name}' no encontrado"}

      team ->
        case team.project_id do
          nil ->
            {:error, "El equipo '#{team_name}' no tiene un proyecto registrado"}

          project_id ->
            # Obtener feedback de todos los mentores para este proyecto
            all_mentors = RepoBehavior.list_mentors(repo)

            feedback_list =
              all_mentors
              |> Enum.flat_map(fn mentor ->
                mentor_data = struct(Domain.Mentor, mentor)
                Domain.Mentor.obtener_feedback_por_proyecto(mentor_data, project_id)
              end)

            {:ok, feedback_list}
        end
    end
  end

  @doc """
  Obtiene el feedback específico de un mentor para un proyecto
  """
  def get_mentor_feedback(repo, team_name, mentor_name) do
    case get_project_feedback(repo, team_name) do
      {:ok, feedback} ->
        mentor_feedback = Enum.filter(feedback, fn fb ->
          # Buscar el mentor por nombre
          mentor = RepoBehavior.get_mentor(repo, fb.mentor_id)
          mentor && mentor.nombre == mentor_name
        end)
        {:ok, mentor_feedback}

      error ->
        error
    end
  end

  @doc """
  Lista todo el feedback de todos los proyectos
  """
  def list_all_feedback(repo) do
    all_mentors = RepoBehavior.list_mentors(repo)

    feedback_list =
      all_mentors
      |> Enum.flat_map(fn mentor ->
        mentor_data = struct(Domain.Mentor, mentor)
        Enum.map(mentor_data.feedback_dado, fn feedback ->
          %{
            mentor: mentor.nombre,
            project_id: feedback.proyecto_id,
            message: feedback.mensaje,
            date: feedback.fecha,
            suggestions: feedback.sugerencias,
            rating: feedback.calificacion
          }
        end)
      end)

    {:ok, feedback_list}
  end

  @doc """
  Obtiene estadísticas de feedback
  """
  def get_feedback_stats(repo) do
    case list_all_feedback(repo) do
      {:ok, feedback} ->
        total_feedback = length(feedback)
        feedback_with_rating = Enum.filter(feedback, & &1.rating)
        average_rating = if Enum.any?(feedback_with_rating) do
          Enum.reduce(feedback_with_rating, 0, fn fb, acc -> acc + fb.rating end) / length(feedback_with_rating)
        else
          0
        end

        %{
          total_feedback: total_feedback,
          average_rating: Float.round(average_rating, 2),
          feedback_with_rating: length(feedback_with_rating)
        }

      {:error, reason} ->
        {:error, reason}
    end
  end
end
