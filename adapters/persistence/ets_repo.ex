defmodule Adapters.Persistence.ETSRepo do
  @behaviour Adapters.Persistence.RepoBehavior

  @participants_table :participants_table
  @teams_table        :teams_table
  @projects_table     :projects_table
  @mentors_table      :mentors_table

  @messages_table       :messages_table       # mensajes por equipo
  @global_messages_table :global_messages_table

  # ============================================================
  #  INIT: se llama al arrancar el CLI o al supervisor
  # ============================================================
  def start_link() do
    create_table(@participants_table)
    create_table(@teams_table)
    create_table(@projects_table)
    create_table(@mentors_table)

    create_table(@messages_table)
    create_table(@global_messages_table)

    {:ok, self()}
  end

  defp create_table(name) do
    :ets.new(name, [:named_table, :set, :public, read_concurrency: true])
  rescue
    _ -> :ok     # si ya existe la tabla, no explota
  end

  # ============================================================
  # PARTICIPANTS (PARTICIPANTES)
  # ============================================================
  def save_participant(participant) do
    :ets.insert(@participants_table, {participant.id, participant})
    :ok
  end

  def get_participant(id) do
    case :ets.lookup(@participants_table, id) do
      [{^id, participant}] -> participant
      _ -> nil
    end
  end

  def list_participants() do
    :ets.tab2list(@participants_table)
    |> Enum.map(fn {_id, participant} -> participant end)
  end

  # ============================================================
  # TEAMS (EQUIPOS)
  # ============================================================
  def save_team(team) do
    :ets.insert(@teams_table, {team.id, team})
    :ok
  end

  def get_team(id) do
    case :ets.lookup(@teams_table, id) do
      [{^id, team}] -> team
      _ -> nil
    end
  end

  def list_teams() do
    :ets.tab2list(@teams_table)
    |> Enum.map(fn {_id, team} -> team end)
  end

  # ============================================================
  # PROJECTS (PROYECTOS)
  # ============================================================
  def save_project(project) do
    :ets.insert(@projects_table, {project.id, project})
    :ok
  end

  def get_project(id) do
    case :ets.lookup(@projects_table, id) do
      [{^id, project}] -> project
      _ -> nil
    end
  end

  def list_projects() do
    :ets.tab2list(@projects_table)
    |> Enum.map(fn {_id, p} -> p end)
  end

  def get_project_by_team(team_id) do
    :ets.tab2list(@projects_table)
    |> Enum.map(fn {_id, p} -> p end)
    |> Enum.find(fn p -> p.team_id == team_id end)
  end

  # ============================================================
  # MENTORES
  # ============================================================
  def save_mentor(mentor) do
    :ets.insert(@mentors_table, {mentor.id, mentor})
    :ok
  end

  def get_mentor(id) do
    case :ets.lookup(@mentors_table, id) do
      [{^id, mentor}] -> mentor
      _ -> nil
    end
  end

  def list_mentors() do
    :ets.tab2list(@mentors_table)
    |> Enum.map(fn {_id, m} -> m end)
  end

  # ============================================================
  # MENSAJES POR EQUIPO
  # messages_table = {team_id, [msg1, msg2, msg3]}
  # ============================================================
  def save_message(team_id, msg) do
    msgs =
      case :ets.lookup(@messages_table, team_id) do
        [{^team_id, list}] -> [msg | list]
        _ -> [msg]
      end

    :ets.insert(@messages_table, {team_id, msgs})
    :ok
  end

  def list_messages(team_id) do
    case :ets.lookup(@messages_table, team_id) do
      [{^team_id, msgs}] -> Enum.reverse(msgs)
      _ -> []
    end
  end

  # MENSAJES GLOBALES
  def save_global_message(msg) do
    list =
      case :ets.lookup(@global_messages_table, :global) do
        [global: msgs] -> [msg | msgs]
        _ -> [msg]
      end

    :ets.insert(@global_messages_table, {:global, list})
    :ok
  end

  def list_global_messages() do
    case :ets.lookup(@global_messages_table, :global) do
      [global: msgs] -> Enum.reverse(msgs)
      _ -> []
    end
  end

  # ============================================================
  # ANUNCIOS (Save announcements as global messages)
  # ============================================================
  def save_announcement(announcement) do
    save_global_message(announcement)
  end

  def list_announcements(limit) do
    list_global_messages()
    |> Enum.take(limit)
  end
end
