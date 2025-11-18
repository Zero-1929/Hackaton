# Domain/proyecto.ex
defmodule Domain.Proyecto do
  @moduledoc """
  Entidad de dominio: Proyecto de Hackathon
  """

  @enforce_keys [:id, :nombre, :descripcion, :categoria]
  defstruct [
    :id,
    :nombre,
    :descripcion,
    :categoria,
    equipo_id: nil,
    estado: "nuevo",
    avances: []
  ]

  @type avance :: %{
    mensaje: String.t(),
    fecha: DateTime.t()
  }

  @type t :: %__MODULE__{
    id: String.t(),
    nombre: String.t(),
    descripcion: String.t(),
    categoria: String.t(),
    equipo_id: String.t() | nil,
    estado: String.t(),
    avances: list(avance())
  }

  @estados_validos ["nuevo", "en_progreso", "finalizado", "cancelado"]

  @doc "Crea un nuevo proyecto"
  @spec nuevo(String.t(), String.t(), String.t(), String.t()) :: t()
  def nuevo(nombre, descripcion, categoria, equipo_id) do
    %__MODULE__{
      id: generar_id(),
      nombre: nombre,
      descripcion: descripcion,
      categoria: categoria,
      equipo_id: equipo_id,
      estado: "nuevo",
      avances: []
    }
  end

  @doc "Actualiza el avance del proyecto"
  @spec actualizar_avance(t(), String.t()) :: t()
  def actualizar_avance(%__MODULE__{avances: avances} = proyecto, mensaje) do
    nuevo_avance = %{
      mensaje: mensaje,
      fecha: DateTime.utc_now()
    }

    nuevo_estado = if proyecto.estado == "nuevo", do: "en_progreso", else: proyecto.estado

    %{proyecto |
      avances: [nuevo_avance | avances],
      estado: nuevo_estado
    }
  end

  @doc "Cambia el estado del proyecto"
  @spec cambiar_estado(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def cambiar_estado(%__MODULE__{} = proyecto, nuevo_estado) do
    if nuevo_estado in @estados_validos do
      {:ok, %{proyecto | estado: nuevo_estado}}
    else
      {:error, :estado_invalido}
    end
  end

  @doc "Obtiene el progreso del proyecto en porcentaje"
  @spec calcular_progreso(t()) :: non_neg_integer()
  def calcular_progreso(%__MODULE__{estado: estado, avances: avances}) do
    case estado do
      "nuevo" -> 0
      "en_progreso" -> min(25 + length(avances) * 15, 90)
      "finalizado" -> 100
      "cancelado" -> 0
      _ -> 0
    end
  end

  @doc "Filtra proyectos por categoría"
  @spec filtrar_por_categoria(list(t()), String.t()) :: list(t())
  def filtrar_por_categoria(proyectos, categoria) do
    Enum.filter(proyectos, &(&1.categoria == categoria))
  end

  @doc "Filtra proyectos por estado"
  @spec filtrar_por_estado(list(t()), String.t()) :: list(t())
  def filtrar_por_estado(proyectos, estado) do
    Enum.filter(proyectos, &(&1.estado == estado))
  end

  # Privadas
  defp generar_id do
    timestamp = System.system_time(:millisecond)
    random = :rand.uniform(9999)
    "PRJ-#{timestamp}-#{random}"
  end
end
