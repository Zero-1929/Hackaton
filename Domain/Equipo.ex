defmodule Equipo do

  defstruct [:id, :nombre, :tema, :miembros]

  def crear(id, nombre, tema, miembros) do
    %Equipo{id: id, nombre: nombre, tema: tema, miembros: miembros}
  end

end
