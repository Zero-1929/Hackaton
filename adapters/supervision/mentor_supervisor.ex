defmodule Adapters.Supervision.MentorSupervisor do
  @moduledoc """
  Supervisor dinámico para los canales de mentoría.

  Su responsabilidad:
    • Crear procesos de mentoría bajo demanda.
    • Supervisarlos (restart: temporary).
    • Servir como intermediario para MessageBroker u otros componentes.
  """

  use DynamicSupervisor

  # ----------------------------------------------------
  # INICIALIZACIÓN DEL SUPERVISOR
  # ----------------------------------------------------
  @doc """
  Se usa para iniciar el supervisor.

  IMPORTANTE:
  Debe ser arrancado desde main.exs o desde un árbol raíz.
  """
  def start_link(init_arg \\ []) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # Cada proceso de mentoría se reinicia solo si es necesario, y no revive si termina normalmente.
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # ----------------------------------------------------
  # API PÚBLICA
  # ----------------------------------------------------

  @doc """
  Inicia un proceso hijo bajo el supervisor.

  Recibe un spec típico:
     {Modulo, opciones}

  Ejemplo:
     start_channel({MentorChannel, team_id: 10})
  """
  def start_channel(child_spec) do
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Apaga un proceso hijo.
  Se usa cuando un canal ya no es necesario.
  """
  def stop_channel(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
