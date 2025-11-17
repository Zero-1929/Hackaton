defmodule Adapters.Supervision.ChatSupervisor do
  @moduledoc """
  Supervisor de todos los procesos relacionados al chat:

    • Registry (para nombres dinámicos)
    • MessageBroker (proceso central)
    • DynamicSupervisor para ChatChannel por equipo
  """

  use Supervisor

  alias Adapters.Messaging.MessageBroker

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    children = [
      # 1. Registry global para canales dinámicos
      %{
        id: HackathonRegistry,
        start: {Registry, :start_link, [
          keys: :unique,
          name: HackathonRegistry
        ]}
      },

      # 2. Supervisor dinámico para canales (ChatChannel)
      %{
        id: ChatChannelSupervisor,
        start: {DynamicSupervisor, :start_link, [
          strategy: :one_for_one,
          name: ChatChannelSupervisor
        ]}
      },

      # 3. MessageBroker como proceso central
      %{
        id: MessageBroker,
        start: {MessageBroker, :start_link, []},
        type: :worker
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
