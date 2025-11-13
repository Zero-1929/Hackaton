defmodule Services.ProjectService do
  @moduledoc """
  Servicio para gestión de proyectos
  """

  alias Services.TeamService
  alias Domain.Proyecto
  alias Adapters.Persistence.RepoBehavior

  @doc """
  Obtiene la información del proyecto de un equipo por nombre
  """
  def get_project_by_team_name(repo, team_name) do
    case TeamService.get_team_by_name(repo, team_name) do
      nil -> nil
      team -> RepoBehavior.get_project_by_team(repo, team.id)
    end
  end

  @doc """
  Crea un proyecto para un equipo
  """
  def create_project(repo, team_name, project_name, category, description) do
    case TeamService.get_team_by_name(repo, team_name) do
      nil ->
        {:error, "Equipo '#{team_name}' no encontrado"}

      team ->
        project_id = Domain.Value_objects.ID_proyecto.generar()

        proyecto = Proyecto.crear(project_id, project_name, description, category, "nuevo", [])

        project_data = %{
          id: proyecto.id,
          name: proyecto.titulo,
          description: proyecto.descripcion,
          category: proyecto.categoria,
          team_id: team.id,
          progress: proyecto.avances || [],
          estado: proyecto.estado
        }

        RepoBehavior.save_project(repo, project_data)

        # Actualizar equipo con referencia al proyecto
        updated_team = %{team | project_id: project_id}
        RepoBehavior.save_team(repo, updated_team)

        {:ok, project_data}
    end
  end

  @doc """
  Agrega un avance al proyecto de un equipo
  """
  def add_progress(repo, team_name, progress_text) do
    case get_project_by_team_name(repo, team_name) do
      nil ->
        {:error, "Proyecto no encontrado para el equipo '#{team_name}'"}

      project ->
        proyecto_domain = Proyecto.crear(
          project.id,
          project.name,
          project.description,
          project.category,
          project.estado,
          project.progress
        )

        proyecto_actualizado = Proyecto.actualizar_avance(proyecto_domain, progress_text)

        updated_project = %{
          project |
          progress: proyecto_actualizado.avances,
          estado: proyecto_actualizado.estado
        }

        RepoBehavior.save_project(repo, updated_project)
        {:ok, updated_project}
    end
  end

  @doc """
  Lista todos los proyectos
  """
  def list_projects(repo) do
    RepoBehavior.list_projects(repo)
  end

  @doc """
  Consulta proyectos por categoría
  """
  def get_projects_by_category(repo, category) do
    projects = RepoBehavior.list_projects(repo)
    Proyecto.consultar_por_categoria(projects, category)
  end

  @doc """
  Consulta proyectos por estado
  """
  def get_projects_by_status(repo, status) do
    projects = RepoBehavior.list_projects(repo)
    Proyecto.consultar_por_estado(projects, status)
  end
end
