defmodule Services.TeamService do
  @moduledoc """
  Servicio para gestión de equipos y participantes
  """

  alias Domain.{Equipo, Participante}
  alias Adapters.Persistence.RepoBehavior

  @doc """
  Lista todos los equipos registrados
  """
  def list_teams(repo) do
    RepoBehavior.list_teams(repo)
    |> Enum.map(fn team_data ->
      participants =
        team_data.participant_ids
        |> Enum.map(&RepoBehavior.get_participant(repo, &1))
        |> Enum.filter(& &1)

      %{
        id: team_data.id,
        name: team_data.nombre || team_data.name,
        category: team_data.categoria || team_data.category,
        participants: participants,
        participant_count: length(participants),
        project: if(team_data.project_id, do: RepoBehavior.get_project(repo, team_data.project_id), else: nil)
      }
    end)
  end

  @doc """
  Busca un equipo por nombre
  """
  def get_team_by_name(repo, team_name) do
    RepoBehavior.list_teams(repo)
    |> Enum.find(fn team ->
      team_name == (team.nombre || team.name)
    end)
  end

  @doc """
  Crea un nuevo equipo
  """
  def create_team(repo, team_name, category) do
    team_id = Domain.Value_objects.ID_equipo.generar()

    equipo = Equipo.crear_por_tema(team_id, team_name, category)

    team_data = %{
      id: equipo.id,
      nombre: equipo.nombre,
      categoria: equipo.tema,
      participant_ids: [],
      project_id: nil
    }

    RepoBehavior.save_team(repo, team_data)
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

        RepoBehavior.save_participant(repo, participant_data)

        # Actualizar equipo con nuevo participante
        updated_participant_ids = [participant_id | (team.participant_ids || [])]
        updated_team = %{team | participant_ids: updated_participant_ids}
        RepoBehavior.save_team(repo, updated_team)

        {:ok, updated_team}
    end
  end

  @doc """
  Lista todos los participantes
  """
  def list_participants(repo) do
    RepoBehavior.list_participants(repo)
  end
end
