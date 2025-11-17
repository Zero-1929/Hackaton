defmodule Adapters.Supervision.TeamSupervisor do
  @moduledoc """
  Supervisor dinámico encargado de manejar procesos relacionados a equipos.

  Cada equipo puede tener sus propios procesos independientes, por ejemplo:
    - Canales internos del equipo
    - Proceso del proyecto
    - Módulos de tracking
    - Lo que se necesite agregar más adelante

  Funciona igual que los otros supervisores del sistema.
  """

  use DynamicSupervisor

  # =======================================================
  # INICIO DEL SUPERVISOR
  # =======================================================

  def start_link(_args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    # Estrategia "one_for_one": si un proceso del equipo muere, solo ese se reinicia.
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # =======================================================
  # API PÚBLICA
  # =======================================================

  @doc """
  Inicia un proceso hijo dentro del supervisor.

  Ejemplo de uso:
      TeamSupervisor.start_child({TeamWorker, team_id: 42})

  Recibe un `child_spec` como cualquier DynamicSupervisor.
  """
  def start_child(child_spec) do
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Finaliza un proceso hijo si está corriendo.

  Útil si un equipo se elimina del sistema.
  """
  def terminate_child(pid) when is_pid(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end

  @doc """
  Lista todos los hijos actuales: procesos activos por equipo.
  """
  def list_children do
    DynamicSupervisor.which_children(__MODULE__)
  end
end
