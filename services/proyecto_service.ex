# Services/proyecto_service.ex
defmodule Services.ProyectoService do
  @moduledoc """
  Servicio de aplicación para gestión de proyectos
  """

  alias Domain.Proyecto
  alias Adapters.Persistence.ETSRepo
  alias Services.EquipoService

  @doc "Crea un nuevo proyecto para un equipo"
  @spec crear_proyecto(String.t(), String.t(), String.t(), String.t()) :: {:ok, Proyecto.t()} | {:error, atom()}
  def crear_proyecto(nombre_equipo, nombre_proyecto, descripcion, categoria) do
    case EquipoService.obtener_por_nombre(nombre_equipo) do
      nil ->
        {:error, :equipo_no_encontrado}

      equipo ->
        # Verificar que el equipo no tenga ya un proyecto
        if equipo.proyecto_id do
          {:error, :equipo_ya_tiene_proyecto}
        else
          proyecto = Proyecto.nuevo(nombre_proyecto, descripcion, categoria, equipo.id)
          ETSRepo.guardar_proyecto(proyecto)

          # Asignar proyecto al equipo
          EquipoService.asignar_proyecto(equipo.id, proyecto.id)

          {:ok, proyecto}
        end
    end
  end

  @doc "Obtiene el proyecto de un equipo"
  @spec obtener_por_equipo(String.t()) :: Proyecto.t() | nil
  def obtener_por_equipo(nombre_equipo) do
    case EquipoService.obtener_por_nombre(nombre_equipo) do
      nil -> nil
      equipo -> ETSRepo.obtener_proyecto_por_equipo(equipo.id)
    end
  end

  @doc "Actualiza el avance de un proyecto"
  @spec actualizar_avance(String.t(), String.t()) :: {:ok, Proyecto.t()} | {:error, atom()}
  def actualizar_avance(nombre_equipo, mensaje_avance) do
    case obtener_por_equipo(nombre_equipo) do
      nil ->
        {:error, :proyecto_no_encontrado}

      proyecto ->
        proyecto_actualizado = Proyecto.actualizar_avance(proyecto, mensaje_avance)
        ETSRepo.guardar_proyecto(proyecto_actualizado)
        {:ok, proyecto_actualizado}
    end
  end

  @doc "Cambia el estado de un proyecto"
  @spec cambiar_estado(String.t(), String.t()) :: {:ok, Proyecto.t()} | {:error, atom()}
  def cambiar_estado(nombre_equipo, nuevo_estado) do
    case obtener_por_equipo(nombre_equipo) do
      nil ->
        {:error, :proyecto_no_encontrado}

      proyecto ->
        case Proyecto.cambiar_estado(proyecto, nuevo_estado) do
          {:ok, proyecto_actualizado} ->
            ETSRepo.guardar_proyecto(proyecto_actualizado)
            {:ok, proyecto_actualizado}

          error ->
            error
        end
    end
  end

  @doc "Lista todos los proyectos"
  @spec listar_proyectos() :: list(Proyecto.t())
  def listar_proyectos do
    ETSRepo.listar_proyectos()
  end

  @doc "Filtra proyectos por categoría"
  @spec filtrar_por_categoria(String.t()) :: list(Proyecto.t())
  def filtrar_por_categoria(categoria) do
    proyectos = ETSRepo.listar_proyectos()
    Proyecto.filtrar_por_categoria(proyectos, categoria)
  end

  @doc "Filtra proyectos por estado"
  @spec filtrar_por_estado(String.t()) :: list(Proyecto.t())
  def filtrar_por_estado(estado) do
    proyectos = ETSRepo.listar_proyectos()
    Proyecto.filtrar_por_estado(proyectos, estado)
  end

  @doc "Obtiene información completa del proyecto con progreso"
  @spec info_completa(String.t()) :: map() | nil
  def info_completa(nombre_equipo) do
    case obtener_por_equipo(nombre_equipo) do
      nil ->
        nil

      proyecto ->
        %{
          proyecto: proyecto,
          progreso: Proyecto.calcular_progreso(proyecto),
          cantidad_avances: length(proyecto.avances),
          ultimo_avance: List.first(proyecto.avances)
        }
    end
  end
end
