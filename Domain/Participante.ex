defmodule Participantes do

  defstruct [:id, :nombre, :email]

   def crear(id, nombre, email) do
     %Participante{id: id, nombre: nombre, email: email}
   end


end
