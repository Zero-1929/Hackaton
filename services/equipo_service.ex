defmodule Services.EquipoService do
  @moduledoc """
  Servicio de aplicación encargado de la gestión de equipos.
  """

  alias Domain.{Equipo, Participante}
  alias Adapters.Persistence.ETSRepo

  # CREACIÓN Y CONSULTA DE EQUIPOS

  @doc """
  Crea un nuevo equipo si el nombre no está en uso.
  """
  @spec crear_equipo(String.t(), String.t()) :: {:ok, Equipo.t()} | {:error, atom()}
  def crear_equipo(nombre, categoria) do
    case ETSRepo.buscar_equipo_por_nombre(nombre) do
      nil ->
        equipo = Equipo.nuevo(nombre, categoria)
        ETSRepo.guardar_equipo(equipo)
        {:ok, equipo}

      _ ->
        {:error, :equipo_ya_existe}
    end
  end

  @doc """
  Lista todos los equipos registrados.
  """
  @spec listar_equipos() :: list(Equipo.t())
  def listar_equipos do
    ETSRepo.listar_equipos()
  end

  @doc """
  Lista únicamente los equipos que se encuentren activos.

  Un equipo se considera activo si `equipo.activo == true`.
  """
  @spec listar_equipos_activos() :: list(Equipo.t())
  def listar_equipos_activos do
    ETSRepo.listar_equipos()
    |> Enum.filter(& &1.activo)
  end

  @doc """
  Busca y obtiene un equipo por su nombre.
  """
  @spec obtener_por_nombre(String.t()) :: Equipo.t() | nil
  def obtener_por_nombre(nombre) do
    ETSRepo.buscar_equipo_por_nombre(nombre)
  end

  @doc """
  Obtiene un equipo por su ID único.
  """
  @spec obtener_por_id(String.t()) :: Equipo.t() | nil
  def obtener_por_id(id) do
    ETSRepo.obtener_equipo(id)
  end

  # GESTIÓN DE PARTICIPANTES EN EQUIPOS

  @doc """
  Añade un participante a un equipo.
  """
  @spec unir_participante(String.t(), String.t()) ::
          {:ok, Equipo.t()} | {:error, atom()}
  def unir_participante(nombre_equipo, participante_id) do
    with %Equipo{} = equipo <- ETSRepo.buscar_equipo_por_nombre(nombre_equipo),
         %Participante{} = participante <- ETSRepo.obtener_participante(participante_id),
         {:ok, equipo_actualizado} <- Equipo.agregar_miembro(equipo, participante_id) do

      participante_actualizado =
        Participante.asignar_equipo(participante, equipo.id)

      ETSRepo.guardar_equipo(equipo_actualizado)
      ETSRepo.guardar_participante(participante_actualizado)

      {:ok, equipo_actualizado}
    else
      nil ->
        {:error, :no_encontrado}

      {:error, razon} ->
        {:error, razon}
    end
  end

  # ASIGNACIÓN DE PROYECTOS

  @doc """
  Asigna un proyecto a un equipo existente.
  """
  @spec asignar_proyecto(String.t(), String.t()) ::
          {:ok, Equipo.t()} | {:error, atom()}
  def asignar_proyecto(equipo_id, proyecto_id) do
    case ETSRepo.obtener_equipo(equipo_id) do
      nil ->
        {:error, :equipo_no_encontrado}

      equipo ->
        equipo_actualizado = Equipo.asignar_proyecto(equipo, proyecto_id)
        ETSRepo.guardar_equipo(equipo_actualizado)
        {:ok, equipo_actualizado}
    end
  end

  # CONSULTA DE INFORMACIÓN DETALLADA

  @doc """
  Obtiene información completa de un equipo
  """
  @spec info_completa(String.t()) :: map() | nil
  def info_completa(nombre_equipo) do
    case ETSRepo.buscar_equipo_por_nombre(nombre_equipo) do
      nil ->
        nil

      equipo ->
        miembros =
          equipo.miembros
          |> Enum.map(&ETSRepo.obtener_participante/1)
          |> Enum.filter(& &1 != nil)

        proyecto =
          if equipo.proyecto_id do
            ETSRepo.obtener_proyecto(equipo.proyecto_id)
          else
            nil
          end

        %{
          equipo: equipo,
          miembros: miembros,
          proyecto: proyecto,
          cantidad_miembros: length(miembros)
        }
    end
  end
end
