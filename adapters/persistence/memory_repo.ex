defmodule Adapters.Persistence.MemoryRepo do
  @behaviour Adapters.Persistence.RepoBehavior

  # Inicialización del repositorio en memoria
  def start_link(_opts) do
    Agent.start_link(fn ->
      %{
        participants: %{},
        teams: %{},
        projects: %{},
        mentors: %{},
        messages: %{},          # %{team_id => [msg1, msg2]}
        global_messages: []     # [msg1, msg2]
      }
    end, name: __MODULE__)
  end

  # PARTICIPANTS

  def save_participant(participant) do
    Agent.update(__MODULE__, fn state ->
      put_in(state[:participants][participant.id], participant)
    end)

    :ok
  end

  def get_participant(id) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state.participants, id)
    end)
  end

  def list_participants() do
    Agent.get(__MODULE__, fn state ->
      Map.values(state.participants)
    end)
  end

  # TEAMS

  def save_team(team) do
    Agent.update(__MODULE__, fn state ->
      put_in(state[:teams][team.id], team)
    end)

    :ok
  end

  def get_team(id) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state.teams, id)
    end)
  end

  def list_teams() do
    Agent.get(__MODULE__, fn state ->
      Map.values(state.teams)
    end)
  end

  # PROJECTS

  def save_project(project) do
    Agent.update(__MODULE__, fn state ->
      put_in(state[:projects][project.id], project)
    end)

    :ok
  end

  def get_project(id) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state.projects, id)
    end)
  end

  def list_projects() do
    Agent.get(__MODULE__, fn state ->
      Map.values(state.projects)
    end)
  end

  def get_project_by_team(team_id) do
    Agent.get(__MODULE__, fn state ->
      state.projects
      |> Map.values()
      |> Enum.find(fn p -> p.team_id == team_id end)
    end)
  end

  # MENTORS

  def save_mentor(mentor) do
    Agent.update(__MODULE__, fn state ->
      put_in(state[:mentors][mentor.id], mentor)
    end)

    :ok
  end

  def get_mentor(id) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state.mentors, id)
    end)
  end

  def list_mentors() do
    Agent.get(__MODULE__, fn state ->
      Map.values(state.mentors)
    end)
  end

  # MESSAGES POR EQUIPO

  def save_message(team_id, msg) do
    Agent.update(__MODULE__, fn state ->
      updated_messages =
        Map.update(state.messages, team_id, [msg], fn existing ->
          [msg | existing]
        end)

      %{state | messages: updated_messages}
    end)

    :ok
  end

  def list_messages(team_id) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state.messages, team_id, [])
      |> Enum.reverse()   # pa q los mensajes aparezcan en orden cronologico
    end)
  end

  # MESSAGES - CANAL GENERAL

  def save_global_message(msg) do
    Agent.update(__MODULE__, fn state ->
      %{state | global_messages: [msg | state.global_messages]}
    end)

    :ok
  end

  def list_global_messages() do
    Agent.get(__MODULE__, fn state ->
      Enum.reverse(state.global_messages)
    end)
  end

  def save_announcement(announcement) do
    save_global_message(announcement)
  end

  def list_announcements(limit) do
    list_global_messages()
    |> Enum.take(limit)
  end
end
