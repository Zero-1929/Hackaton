defmodule Equipo do
  @moduledoc """
  Módulo para gestionar equipos con sus miembros y estado activo.
  """

  defstruct [:id, :nombre, :tema, :miembros, :activo]

  # ==========
  # CONSTRUCTORES
  # ==========

  def crear(id, nombre, tema, miembros),
    do: build_equipo(id, nombre, tema, miembros)

  def crear_por_tema(id, nombre, tema),
    do: build_equipo(id, nombre, tema, [])

  def crear_por_afinidad(id, nombre, tema, miembros) when is_list(miembros),
    do: build_equipo(id, nombre, tema, normalizar_miembros(miembros))

  # ==========
  # ASIGNACIÓN DE PARTICIPANTES
  # ==========

  def asignar_participante(%Equipo{} = equipo, %Participante{id: pid} = participante),
    do: agregar_miembro(equipo, participante, pid)

  def asignar_participante(%Equipo{} = equipo, participante_id) when is_binary(participante_id),
    do: agregar_miembro(equipo, participante_id, participante_id)

  # ==========
  # ESTADO ACTIVO / INACTIVO
  # ==========

  def activar(%Equipo{} = equipo), do: %{equipo | activo: true}
  def desactivar(%Equipo{} = equipo), do: %{equipo | activo: false}

  # ==========
  # LISTAR EQUIPOS
  # ==========

  def listar_activos(equipos) when is_list(equipos),
    do: Enum.filter(equipos, & &1.activo)

  # ==========
  # FUNCIONES PRIVADAS
  # ==========

  defp build_equipo(id, nombre, tema, miembros),
    do: %Equipo{id: id, nombre: nombre, tema: tema, miembros: miembros, activo: true}

  defp agregar_miembro(equipo, miembro, id) do
    miembros = normalizar_miembros(equipo.miembros)

    if miembro_existente?(miembros, id) do
      equipo
    else
      %{equipo | miembros: miembros ++ [miembro]}
    end
  end

  defp normalizar_miembros(nil), do: []
  defp normalizar_miembros(miembros) when is_list(miembros), do: miembros

  defp miembro_existente?(miembros, id) do
    Enum.any?(miembros, fn
      %Participante{id: mid} -> mid == id
      other when is_binary(other) -> other == id
      _ -> false
    end)
  end
end
