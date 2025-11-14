defmodule Mentor do
  @moduledoc """
  Módulo para gestionar mentores, sus consultas y retroalimentación a proyectos.D
  """

  defstruct [
    :id,
    :nombre,
    :email,
    :especialidades,
    :disponible,
    :consultas_pendientes,
    :consultas_respondidas,
    :feedback_dado
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          nombre: String.t(),
          email: String.t(),
          especialidades: [String.t()],
          disponible: boolean(),
          consultas_pendientes: [consulta()],
          consultas_respondidas: [consulta()],
          feedback_dado: [feedback()]
        }

  @type consulta :: %{
          id: String.t(),
          equipo_id: String.t(),
          proyecto_id: String.t(),
          mensaje: String.t(),
          fecha: DateTime.t(),
          estado: :pendiente | :respondida
        }

  @type feedback :: %{
          id: String.t(),
          proyecto_id: String.t(),
          mensaje: String.t(),
          fecha: DateTime.t(),
          sugerencias: [String.t()],
          calificacion: 1..5 | nil
        }

  # ==========
  # CONSTRUCTORES
  # ==========

  @doc "Crea un nuevo mentor con los datos proporcionados."
  @spec crear(String.t(), String.t(), String.t(), [String.t()]) :: t()
  def crear(id, nombre, email, especialidades)
      when is_binary(id) and is_binary(nombre) and is_binary(email) and is_list(especialidades) do
    %__MODULE__{
      id: id,
      nombre: nombre,
      email: email,
      especialidades: especialidades,
      disponible: true,
      consultas_pendientes: [],
      consultas_respondidas: [],
      feedback_dado: []
    }
  end

  @doc "Registra un nuevo mentor generando automáticamente un ID único."
  @spec registrar(String.t(), String.t(), [String.t()]) :: t()
  def registrar(nombre, email, especialidades)
      when is_binary(nombre) and is_binary(email) and is_list(especialidades) do
    crear(generar_id(), nombre, email, especialidades)
  end

  # ==========
  # GESTIÓN DE CONSULTAS
  # ==========

  @doc "Registra una nueva consulta de un equipo para un mentor, si está disponible."
  @spec registrar_consulta(t(), String.t(), String.t(), String.t()) ::
          {:ok, t()} | {:error, String.t()}
  def registrar_consulta(%__MODULE__{disponible: false}, _eq, _pr, _msg),
    do: {:error, "El mentor no está disponible actualmente"}

  def registrar_consulta(%__MODULE__{} = mentor, equipo_id, proyecto_id, mensaje)
      when is_binary(equipo_id) and is_binary(proyecto_id) and is_binary(mensaje) do
    existe =
      Enum.any?(mentor.consultas_pendientes, fn c ->
        c.proyecto_id == proyecto_id and c.equipo_id == equipo_id and c.estado == :pendiente
      end)

    if existe do
      {:error, "Ya existe una consulta pendiente para este proyecto y equipo"}
    else
      consulta = %{
        id: generar_id_consulta(),
        equipo_id: equipo_id,
        proyecto_id: proyecto_id,
        mensaje: mensaje,
        fecha: DateTime.utc_now(),
        estado: :pendiente
      }

      actualizado = %{mentor | consultas_pendientes: [consulta | mentor.consultas_pendientes]}
      {:ok, actualizado}
    end
  end

  @doc "Responde a una consulta pendiente, marcándola como respondida y agregando feedback."
  @spec responder_consulta(t(), String.t(), String.t()) :: {:ok, t()} | {:error, String.t()}
  def responder_consulta(%__MODULE__{} = mentor, consulta_id, respuesta)
      when is_binary(consulta_id) and is_binary(respuesta) do
    case Enum.find(mentor.consultas_pendientes, &(&1.id == consulta_id)) do
      nil ->
        {:error, "Consulta no encontrada"}

      consulta ->
        consulta_actualizada = %{consulta | estado: :respondida}

        feedback = %{
          id: generar_id_feedback(),
          proyecto_id: consulta.proyecto_id,
          mensaje: respuesta,
          fecha: DateTime.utc_now(),
          sugerencias: [],
          calificacion: nil
        }

        consultas_pendientes =
          Enum.reject(mentor.consultas_pendientes, &(&1.id == consulta_id))

        consultas_respondidas = [consulta_actualizada | mentor.consultas_respondidas]
        feedback_dado = [feedback | mentor.feedback_dado]

        actualizado = %{
          mentor
          | consultas_pendientes: consultas_pendientes,
            consultas_respondidas: consultas_respondidas,
            feedback_dado: feedback_dado
        }

        {:ok, actualizado}
    end
  end

  @doc "Obtiene todas las consultas pendientes de un mentor."
  @spec obtener_consultas_pendientes(t()) :: [consulta()]
  def obtener_consultas_pendientes(%__MODULE__{} = mentor), do: mentor.consultas_pendientes

  @doc "Obtiene todas las consultas respondidas de un mentor."
  @spec obtener_consultas_respondidas(t()) :: [consulta()]
  def obtener_consultas_respondidas(%__MODULE__{} = mentor), do: mentor.consultas_respondidas

  # ==========
  # GESTIÓN DE FEEDBACK
  # ==========

  @doc "Agrega retroalimentación a un proyecto."
  @spec agregar_feedback(t(), String.t(), String.t(), [String.t()], integer() | nil) ::
          {:ok, t()} | {:error, String.t()}
  def agregar_feedback(%__MODULE__{} = mentor, proyecto_id, mensaje, sugerencias \\ [], calificacion \\ nil)
      when is_binary(proyecto_id) and is_binary(mensaje) and is_list(sugerencias) and
             (is_nil(calificacion) or (is_integer(calificacion) and calificacion in 1..5)) do
    feedback = %{
      id: generar_id_feedback(),
      proyecto_id: proyecto_id,
      mensaje: mensaje,
      fecha: DateTime.utc_now(),
      sugerencias: sugerencias,
      calificacion: calificacion
    }

    {:ok, %{mentor | feedback_dado: [feedback | mentor.feedback_dado]}}
  end

  @doc "Obtiene todo el feedback dado a un proyecto específico."
  @spec obtener_feedback_por_proyecto(t(), String.t()) :: [feedback()]
  def obtener_feedback_por_proyecto(%__MODULE__{} = mentor, proyecto_id) when is_binary(proyecto_id) do
    Enum.filter(mentor.feedback_dado, &(&1.proyecto_id == proyecto_id))
  end

  @doc "Cambia la disponibilidad del mentor."
  @spec cambiar_disponibilidad(t(), boolean()) :: t()
  def cambiar_disponibilidad(%__MODULE__{} = mentor, disponible) when is_boolean(disponible) do
    %{mentor | disponible: disponible}
  end

  # ==========
  # FUNCIONES PRIVADAS
  # ==========

  defp generar_id do
    uniq = :erlang.unique_integer([:positive, :monotonic])
    "M-#{uniq}"
  end

  defp generar_id_consulta do
    uniq = :erlang.unique_integer([:positive, :monotonic])
    "C-#{uniq}"
  end

  defp generar_id_feedback do
    uniq = :erlang.unique_integer([:positive, :monotonic])
    "F-#{uniq}"
  end
end
