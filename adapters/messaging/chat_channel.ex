defmodule Adapters.Messaging.ChatChannel do
  use GenServer

  alias Adapters.Persistence.RepoBehavior

  # INICIO DEL PROCESO

  @doc """
  Arranca un canal de chat para un equipo.
  El `team_id` se recibe como argumento y se guarda en el estado.
  """
  def start_link(opts) do
    team_id = Keyword.fetch!(opts, :team_id)

    GenServer.start_link(__MODULE__, team_id, name: via(team_id))
  end

  @doc """
  Registra este proceso bajo un nombre dinámico usando Registry o similar.
  Supone que tienes un Registry llamado HackathonRegistry.
  """
  def via(team_id) do
    {:via, Registry, {HackathonRegistry, {:chat_channel, team_id}}}
  end

  # CALLBACKS
  @impl true
  def init(team_id) do
    state = %{
      team_id: team_id,
      online_users: MapSet.new()
    }

    IO.puts("💬 Canal de chat iniciado para el equipo #{team_id}")

    {:ok, state}
  end

  # API PÚBLICA
  @doc """
  Agrega un usuario al canal.
  """
  def join(team_id, user) do
    GenServer.cast(via(team_id), {:join, user})
  end

  @doc """
  Enviar un mensaje al canal.
  """
  def push_message(team_id, user, content) do
    GenServer.cast(via(team_id), {:msg, user, content})
  end

  @doc """
  Obtener historial (lo trae desde el repo).
  """
  def history(repo, team_id) do
    RepoBehavior.list_messages(repo, team_id)
  end

  # HANDLE_CAST
  @impl true
  def handle_cast({:join, user}, state) do
    IO.puts("🟢 #{user.name} se unió al chat del equipo #{state.team_id}")

    new_state = %{
      state
      | online_users: MapSet.put(state.online_users, user.id)
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:msg, user, content}, state) do
    timestamp = DateTime.utc_now() |> DateTime.to_string()

    msg = %{
      id: UUID.uuid4(),
      team_id: state.team_id,
      user: user.name,
      user_id: user.id,
      content: content,
      timestamp: timestamp
    }

    # Guardar en el repositorio persistente
    RepoBehavior.save_message(state.team_id, msg)

    IO.puts("💬 [#{state.team_id}] #{user.name}: #{content}")

    {:noreply, state}
  end
end
