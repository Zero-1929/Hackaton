# Domain/equipo.ex
defmodule Domain.Equipo do
  @moduledoc """
  Entidad de dominio: Equipo de la Hackathon
  """

  @enforce_keys [:id, :nombre, :categoria]
  defstruct [:id, :nombre, :categoria, miembros: [], proyecto_id: nil, activo: true]

  @type t :: %__MODULE__{
    id: String.t(),
    nombre: String.t(),
    categoria: String.t(),
    miembros: list(String.t()),
    proyecto_id: String.t() | nil,
    activo: boolean()
  }

  @doc "Crea un nuevo equipo"
  @spec nuevo(String.t(), String.t()) :: t()
  def nuevo(nombre, categoria) when is_binary(nombre) and is_binary(categoria) do
    %__MODULE__{
      id: generar_id(),
      nombre: nombre,
      categoria: categoria,
      miembros: [],
      proyecto_id: nil,
      activo: true
    }
  end

  @doc "Agrega un miembro al equipo"
  @spec agregar_miembro(t(), String.t()) :: {:ok, t()} | {:error, atom()}
  def agregar_miembro(%__MODULE__{miembros: miembros} = equipo, participante_id) do
    if participante_id in miembros do
      {:error, :ya_es_miembro}
    else
      {:ok, %{equipo | miembros: [participante_id | miembros]}}
    end
  end

  @doc "Asigna un proyecto al equipo"
  @spec asignar_proyecto(t(), String.t()) :: t()
  def asignar_proyecto(%__MODULE__{} = equipo, proyecto_id) do
    %{equipo | proyecto_id: proyecto_id}
  end

  @doc "Activa o desactiva un equipo"
  @spec cambiar_estado(t(), boolean()) :: t()
  def cambiar_estado(%__MODULE__{} = equipo, activo) do
    %{equipo | activo: activo}
  end

  @doc "Cuenta los miembros del equipo"
  @spec contar_miembros(t()) :: non_neg_integer()
  def contar_miembros(%__MODULE__{miembros: miembros}), do: length(miembros)

  # Privadas
  defp generar_id do
    timestamp = System.system_time(:millisecond)
    random = :rand.uniform(9999)
    "TEAM-#{timestamp}-#{random}"
  end
end
