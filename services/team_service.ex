defmodule Services.TeamService do
  @moduledoc """
  Servicio para gestión de equipos y participantes
  """

  alias Domain.Participante
  alias Adapters.Persistence.ETSRepo

  @doc """
  Lista todos los equipos registrados
  """
  def list_teams(_repo) do
    ETSRepo.list_teams()
    |> Enum.map(fn team_data ->
      participants =
        team_data.participant_ids
        |> Enum.map(&ETSRepo.get_participant/1)
        |> Enum.filter(& &1)

      %{
        id: team_data.id,
        name: team_data.nombre || team_data.name,
        category: team_data.categoria || team_data.category,
        participants: participants,
        participant_count: length(participants),
        project: if(team_data.project_id, do: ETSRepo.get_project(team_data.project_id), else: nil)
      }
    end)
  end

  @doc """
  Busca un equipo por nombre
  """
  def get_team_by_name(_repo, team_name) do
    ETSRepo.list_teams()
    |> Enum.find(fn team ->
      team_name == (team.nombre || team.name)
    end)
  end

  @doc """
  Crea un nuevo equipo
  """
  def create_team(_repo, team_name, category) do
    team_id = Domain.Value_objects.ID_equipo.generar()
    team_data = %{
      id: team_id,
      nombre: team_name,
      categoria: category,
      participant_ids: [],
      project_id: nil
    }

    ETSRepo.save_team(team_data)
    {:ok, team_data}
  end

  @doc """
  Une un participante a un equipo
  """
  def join_team(repo, team_name, user) do
    case get_team_by_name(repo, team_name) do
      nil ->
        {:error, :not_found}

      team ->
        participant_id = Domain.Value_objects.ID_participante.generar()

        participante = Participante.registrar(user.name, user.email || "#{user.name}@hackathon.com")

        participant_data = %{
          id: participante.id,
          nombre: participante.nombre,
          email: participante.email,
          team_id: team.id
        }

        ETSRepo.save_participant(participant_data)

        # Actualizar equipo con nuevo participante
        updated_participant_ids = [participant_id | (team.participant_ids || [])]
        updated_team = %{team | participant_ids: updated_participant_ids}
        ETSRepo.save_team(updated_team)

        {:ok, updated_team}
    end
  end

  @doc """
  Lista todos los participantes
  """
  def list_participants(_repo) do
    ETSRepo.list_participants()
  end
end
