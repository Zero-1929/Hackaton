defmodule Adapters.Messaging.MentorChannel do
  @moduledoc """
  Canal de comunicación entre un equipo y sus mentores.

  - Cada equipo tiene su propio canal de mentoría.
  - Los participantes pueden enviar consultas.
  - Los mentores pueden responder.
  - Todo se guarda en el repositorio.
  """

  use GenServer

  alias Adapters.Persistence.RepoBehavior

  # ==========================================================
  # INICIO DEL PROCESO
  # ==========================================================

  @doc """
  Inicia un canal de mentoría para un equipo específico.
  """
  def start_link(opts) do
    team_id = Keyword.fetch!(opts, :team_id)

    GenServer.start_link(__MODULE__, team_id, name: via(team_id))
  end

  @doc """
  Registrar el proceso en un nombre dinámico dentro de un Registry.

  Supone que existe un Registry llamado `HackathonRegistry`.
  """
  def via(team_id) do
    {:via, Registry, {HackathonRegistry, {:mentor_channel, team_id}}}
  end

  # CALLBACK init/1
  @impl true
  def init(team_id) do
    state = %{
      team_id: team_id,
      connected_participants: MapSet.new(),
      connected_mentors: MapSet.new()
    }

    IO.puts("🎓 Canal de mentoría iniciado para el equipo #{team_id}")

    {:ok, state}
  end

  # ==========================================================
  # API PÚBLICA
  # ==========================================================

  @doc """
  Un participante (alumno) se conecta al canal.
  """
  def join_participant(team_id, participant) do
    GenServer.cast(via(team_id), {:join_participant, participant})
  end

  @doc """
  Un mentor se conecta al canal.
  """
  def join_mentor(team_id, mentor) do
    GenServer.cast(via(team_id), {:join_mentor, mentor})
  end

  @doc """
  Un participante envía una consulta.
  """
  def ask(team_id, participant, content) do
    GenServer.cast(via(team_id), {:ask, participant, content})
  end

  @doc """
  Un mentor responde una consulta.
  """
  def reply(team_id, mentor, content) do
    GenServer.cast(via(team_id), {:reply, mentor, content})
  end

  @doc """
  Obtiene el historial completo del canal desde el repositorio.
  """
  def history(repo, team_id) do
    RepoBehavior.list_messages(repo, team_id)
  end

  # ==========================================================
  # HANDLE_CAST
  # ==========================================================

  @impl true
  def handle_cast({:join_participant, participant}, state) do
    IO.puts("🟢 #{participant.name} se unió al canal de mentoría del equipo #{state.team_id}")

    new_state = %{
      state
      | connected_participants: MapSet.put(state.connected_participants, participant.id)
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:join_mentor, mentor}, state) do
    IO.puts("🟣 Mentor #{mentor.name} se conectó al equipo #{state.team_id}")

    new_state = %{
      state
      | connected_mentors: MapSet.put(state.connected_mentors, mentor.id)
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:ask, participant, content}, state) do
    timestamp = DateTime.utc_now() |> DateTime.to_string()

    msg = %{
      id: UUID.uuid4(),
      type: :question,
      team_id: state.team_id,
      sender: participant.name,
      sender_id: participant.id,
      content: content,
      timestamp: timestamp
    }

    RepoBehavior.save_message(state.team_id, msg)

    IO.puts("❓ [#{state.team_id}] #{participant.name} pregunta: #{content}")

    {:noreply, state}
  end

  @impl true
  def handle_cast({:reply, mentor, content}, state) do
    timestamp = DateTime.utc_now() |> DateTime.to_string()

    msg = %{
      id: UUID.uuid4(),
      type: :answer,
      team_id: state.team_id,
      sender: mentor.name,
      sender_id: mentor.id,
      content: content,
      timestamp: timestamp
    }

    RepoBehavior.save_message(state.team_id, msg)

    IO.puts("💬 [#{state.team_id}] Mentor #{mentor.name} responde: #{content}")

    {:noreply, state}
  end
end
