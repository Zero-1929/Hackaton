defmodule Domain.Participante do
  @moduledoc """
  Módulo para gestionar participantes.
  Permite crear y registrar nuevos participantes con identificadores únicos.
  """

  defstruct [:id, :nombre, :email]

  # ==========
  # CONSTRUCTORES
  # ==========

  @doc """
  Crea un participante con un ID, nombre y correo dados explícitamente.
  """
  def crear(id, nombre, email)
      when is_binary(id) and is_binary(nombre) and is_binary(email) do
    %Domain.Participante{id: id, nombre: nombre, email: email}
  end

  @doc """
  Registra un nuevo participante generando automáticamente un ID único.
  """
  def registrar(nombre, email)
      when is_binary(nombre) and is_binary(email) do
    %Domain.Participante{id: generar_id(), nombre: nombre, email: email}
  end

  # ==========
  # FUNCIONES PRIVADAS
  # ==========

  @doc false
  defp generar_id do
    uniq = :erlang.unique_integer([:positive, :monotonic])
    "P-" <> Integer.to_string(uniq)
  end
end
