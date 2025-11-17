# Adapters/Persistence/ets_repo.ex
defmodule Adapters.Persistence.ETSRepo do
  @moduledoc """
  Repositorio de persistencia usando ETS (Erlang Term Storage)
  Almacena datos en memoria durante la ejecución
  """

  use GenServer

  # Nombres de las tablas ETS
  @participantes :participantes_table
  @equipos :equipos_table
  @proyectos :proyectos_table
  @mentores :mentores_table
  @mensajes :mensajes_table
  @salas_tematicas :salas_tematicas_table

  # ============================================================================
  # API Pública (Cliente)
  # ============================================================================

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # --- Participantes ---
  def guardar_participante(participante), do: GenServer.call(__MODULE__, {:guardar, @participantes, participante.id, participante})
  def obtener_participante(id), do: GenServer.call(__MODULE__, {:obtener, @participantes, id})
  def listar_participantes(), do: GenServer.call(__MODULE__, {:listar, @participantes})

  # --- Equipos ---
  def guardar_equipo(equipo), do: GenServer.call(__MODULE__, {:guardar, @equipos, equipo.id, equipo})
  def obtener_equipo(id), do: GenServer.call(__MODULE__, {:obtener, @equipos, id})
  def listar_equipos(), do: GenServer.call(__MODULE__, {:listar, @equipos})
  def buscar_equipo_por_nombre(nombre), do: GenServer.call(__MODULE__, {:buscar_por_nombre, nombre})

  # --- Proyectos ---
  def guardar_proyecto(proyecto), do: GenServer.call(__MODULE__, {:guardar, @proyectos, proyecto.id, proyecto})
  def obtener_proyecto(id), do: GenServer.call(__MODULE__, {:obtener, @proyectos, id})
  def listar_proyectos(), do: GenServer.call(__MODULE__, {:listar, @proyectos})
  def obtener_proyecto_por_equipo(equipo_id), do: GenServer.call(__MODULE__, {:proyecto_por_equipo, equipo_id})

  # --- Mentores ---
  def guardar_mentor(mentor), do: GenServer.call(__MODULE__, {:guardar, @mentores, mentor.id, mentor})
  def obtener_mentor(id), do: GenServer.call(__MODULE__, {:obtener, @mentores, id})
  def listar_mentores(), do: GenServer.call(__MODULE__, {:listar, @mentores})

  # --- Mensajes ---
  def guardar_mensaje(mensaje), do: GenServer.call(__MODULE__, {:guardar_mensaje, mensaje})
  def listar_mensajes(tipo, destino_id, limite \\ 50), do: GenServer.call(__MODULE__, {:listar_mensajes, tipo, destino_id, limite})

  # --- Salas Temáticas ---
  def guardar_sala(sala), do: GenServer.call(__MODULE__, {:guardar, @salas_tematicas, sala.id, sala})
  def obtener_sala(id), do: GenServer.call(__MODULE__, {:obtener, @salas_tematicas, id})
  def listar_salas(), do: GenServer.call(__MODULE__, {:listar, @salas_tematicas})

  # ============================================================================
  # Callbacks de GenServer
  # ============================================================================

  @impl true
  def init(:ok) do
    # Crear todas las tablas ETS
    crear_tabla(@participantes)
    crear_tabla(@equipos)
    crear_tabla(@proyectos)
    crear_tabla(@mentores)
    crear_tabla(@mensajes)
    crear_tabla(@salas_tematicas)

    {:ok, %{}}
  end

  @impl true
  def handle_call({:guardar, tabla, id, dato}, _from, state) do
    :ets.insert(tabla, {id, dato})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:obtener, tabla, id}, _from, state) do
    resultado = case :ets.lookup(tabla, id) do
      [{^id, dato}] -> dato
      [] -> nil
    end
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:listar, tabla}, _from, state) do
    lista = :ets.tab2list(tabla)
            |> Enum.map(fn {_id, dato} -> dato end)
    {:reply, lista, state}
  end

  @impl true
  def handle_call({:buscar_por_nombre, nombre}, _from, state) do
    resultado = :ets.tab2list(@equipos)
                |> Enum.map(fn {_id, equipo} -> equipo end)
                |> Enum.find(&(&1.nombre == nombre))
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:proyecto_por_equipo, equipo_id}, _from, state) do
    resultado = :ets.tab2list(@proyectos)
                |> Enum.map(fn {_id, proyecto} -> proyecto end)
                |> Enum.find(&(&1.equipo_id == equipo_id))
    {:reply, resultado, state}
  end

  @impl true
  def handle_call({:guardar_mensaje, mensaje}, _from, state) do
    # Clave compuesta: {tipo, destino_id, timestamp}
    clave = {mensaje.tipo, mensaje.destino_id, System.system_time(:millisecond)}
    :ets.insert(@mensajes, {clave, mensaje})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:listar_mensajes, tipo, destino_id, limite}, _from, state) do
    mensajes = :ets.tab2list(@mensajes)
               |> Enum.filter(fn {{t, d, _ts}, _msg} -> t == tipo and d == destino_id end)
               |> Enum.sort_by(fn {{_t, _d, ts}, _msg} -> ts end, :desc)
               |> Enum.take(limite)
               |> Enum.map(fn {_key, msg} -> msg end)
    {:reply, mensajes, state}
  end

  # ============================================================================
  # Funciones privadas
  # ============================================================================

  defp crear_tabla(nombre) do
    :ets.new(nombre, [:named_table, :set, :public, read_concurrency: true])
  rescue
    ArgumentError -> :ok  # La tabla ya existe
  end
end
