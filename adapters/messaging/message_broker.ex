defmodule Adapters.Messaging.MessageBroker do
  @moduledoc """
  Capa de orquestación para los canales de chat.

  Responsable de:
    • Garantizar que un canal exista antes de enviar mensajes.
    • Delegar join/send/history al ChatChannel.
    • Interactuar con el ChatSupervisor (dynamic supervisor).
  """

  alias Adapters.Messaging.ChatChannel
  alias Adapters.Persistence.RepoBehavior

  # Supervisor que maneja los canales dinámicos
  @supervisor Adapters.Supervision.ChatSupervisor

  # ======================================================
  # API PÚBLICA
  # ======================================================

  @doc """
  Asegura que el canal del equipo exista, si no lo crea.
  """
  def ensure_channel(team_id) do
    case find_channel(team_id) do
      {:ok, _pid} ->
        :ok

      {:error, :not_found} ->
        start_channel(team_id)
    end
  end

  @doc """
  Unirse al canal: garantiza que exista, luego delega.
  """
  def join(team_id, user) do
    ensure_channel(team_id)
    ChatChannel.join(team_id, user)
  end

  @doc """
  Enviar mensaje al canal especificado.
  """
  def send_message(team_id, user, content) do
    ensure_channel(team_id)
    ChatChannel.push_message(team_id, user, content)
  end

  @doc """
  Obtener historial de mensajes desde el repositorio.
  """
  def history(repo, team_id) do
    ChatChannel.history(repo, team_id)
  end


  # FUNCIONES PRIVADAS

  # Para saber si un canal ya está registrado
  defp find_channel(team_id) do
    case Registry.lookup(HackathonRegistry, {:chat_channel, team_id}) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  # Crear el canal bajo el supervisor dinámico
  defp start_channel(team_id) do
    spec = {ChatChannel, team_id: team_id}

    case DynamicSupervisor.start_child(@supervisor, spec) do
      {:ok, _pid} ->
        IO.puts("✅ Canal creado para el equipo #{team_id}")
        :ok

      {:error, {:already_started, _pid}} ->
        :ok

      {:error, reason} ->
        IO.puts("❌ Error al iniciar canal: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def start_link(_) do
  GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
end

# callback
def init(_) do
  {:ok, %{}}
end

end
