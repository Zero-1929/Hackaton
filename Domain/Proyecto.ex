defmodule Proyecto do
  @moduledoc """
  Módulo para gestionar proyectos: creación, registro de ideas, avances y consultas.
  """

  defstruct [:id, :titulo, :descripcion, :categoria, :estado, :avances]

  # ==========
  # CONSTRUCTORES
  # ==========

  def crear(id, titulo, descripcion, categoria, estado \\ "nuevo", avances \\ [])
      when is_binary(id) and is_binary(titulo) and is_binary(descripcion) and is_binary(categoria) do
    %Proyecto{
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      categoria: categoria,
      estado: estado,
      avances: avances
    }
  end

  def subir_proyecto(id, titulo, descripcion, categoria),
    do: crear(id, titulo, descripcion, categoria, "nuevo", [])

  def registrar_idea(titulo, descripcion, categoria),
    do: crear(generar_id(), titulo, descripcion, categoria, "nuevo", [])

  # ==========
  # ACTUALIZACIONES
  # ==========

  def actualizar_avance(%Proyecto{} = proyecto, mensaje) when is_binary(mensaje) do
    avance = %{mensaje: mensaje, fecha: DateTime.utc_now()}
    avances = normalizar_avances(proyecto.avances) ++ [avance]
    nuevo_estado = if proyecto.estado in [nil, "nuevo"], do: "en_progreso", else: proyecto.estado
    %{proyecto | avances: avances, estado: nuevo_estado}
  end

  def set_estado(%Proyecto{} = proyecto, estado)
      when estado in ["nuevo", "en_progreso", "finalizado", "cancelado"] do
    %{proyecto | estado: estado}
  end

  # ==========
  # CONSULTAS
  # ==========

  def consultar_por_categoria(proyectos, categoria)
      when is_list(proyectos) and is_binary(categoria),
      do: Enum.filter(proyectos, &(&1.categoria == categoria))

  def consultar_por_estado(proyectos, estado)
      when is_list(proyectos) and is_binary(estado),
      do: Enum.filter(proyectos, &(&1.estado == estado))

  # ==========
  # FUNCIONES PRIVADAS
  # ==========

  defp generar_id do
    uniq = :erlang.unique_integer([:positive, :monotonic])
    "PR-" <> Integer.to_string(uniq)
  end

  defp normalizar_avances(nil), do: []
  defp normalizar_avances(avances) when is_list(avances), do: avances
end
