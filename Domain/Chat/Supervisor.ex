defmodule Domain.Chat.Supervisor do
  @moduledoc """
  Supervisor para los procesos relacionados con el chat.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      # Inicia el servidor de chat
      {Domain.Chat.ServidorChat, name: Domain.Chat.ServidorChat}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
