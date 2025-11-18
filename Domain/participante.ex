# Domain/participante.ex
defmodule Domain.Participante do
  @moduledoc """
  Entidad de dominio: Participante de la Hackathon
  """

  @enforce_keys [:id, :nombre, :email]
  defstruct [:id, :nombre, :email, equipo_id: nil]

  @type t :: %__MODULE__{
    id: String.t(),
    nombre: String.t(),
    email: String.t(),
    equipo_id: String.t() | nil
  }

  @doc "Crea un nuevo participante con ID autogenerado"
  @spec nuevo(String.t(), String.t()) :: t()
  def nuevo(nombre, email) when is_binary(nombre) and is_binary(email) do
    %__MODULE__{
      id: generar_id(),
      nombre: nombre,
      email: email,
      equipo_id: nil
    }
  end

  @doc "Asigna un participante a un equipo"
  @spec asignar_equipo(t(), String.t()) :: t()
  def asignar_equipo(%__MODULE__{} = participante, equipo_id) do
    %{participante | equipo_id: equipo_id}
  end

  @doc "Valida que un participante tenga datos correctos"
  @spec valido?(t()) :: boolean()
  def valido?(%__MODULE__{nombre: nombre, email: email}) do
    String.trim(nombre) != "" and String.contains?(email, "@")
  end

  # Privadas
  defp generar_id do
    timestamp = System.system_time(:millisecond)
    random = :rand.uniform(9999)
    "P-#{timestamp}-#{random}"
  end
end
