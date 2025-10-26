defmodule Equipo do

  defstruct [:id, :nombre, :tema, :miembros]

  def crear(id, nombre, equipo, miembros) do
    %Equipo{id: id, nombre: nombre, tema: tema, miembros: miembros}
  end

end
