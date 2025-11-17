defmodule Domain.Value_objects do
  @moduledoc """
  Módulo que contiene todos los Value Objects del Domain.
  """

  defmodule ID_equipo do
    @enforce_keys [:valor]
    defstruct [:valor]

    @type t :: %__MODULE__{valor: String.t()}

    def new(valor) when is_binary(valor) and byte_size(valor) > 0 do
      %__MODULE__{valor: valor}
    end

    def generar do
      uniq = :erlang.unique_integer([:positive, :monotonic])
      valor = "TEAM-" <> Integer.to_string(uniq)
      %__MODULE__{valor: valor}
    end
  end

  defmodule ID_participante do
    @enforce_keys [:valor]
    defstruct [:valor]

    @type t :: %__MODULE__{valor: String.t()}

    def new(valor) when is_binary(valor) and byte_size(valor) > 0 do
      %__MODULE__{valor: valor}
    end

    def generar do
      uniq = :erlang.unique_integer([:positive, :monotonic])
      valor = "PART-" <> Integer.to_string(uniq)
      %__MODULE__{valor: valor}
    end
  end

  defmodule ID_mensaje do
    @enforce_keys [:valor]
    defstruct [:valor]

    @type t :: %__MODULE__{valor: String.t()}

    def generar do
      uniq = :erlang.unique_integer([:positive, :monotonic])
      valor = "MSG-" <> Integer.to_string(uniq)
      %__MODULE__{valor: valor}
    end
  end

  defmodule ID_mentor do
    @enforce_keys [:valor]
    defstruct [:valor]

    @type t :: %__MODULE__{valor: String.t()}

    def generar do
      uniq = :erlang.unique_integer([:positive, :monotonic])
      valor = "MTR-" <> Integer.to_string(uniq)
      %__MODULE__{valor: valor}
    end
  end

  defmodule ID_proyecto do
    @enforce_keys [:valor]
    defstruct [:valor]

    @type t :: %__MODULE__{valor: String.t()}

    def generar do
      uniq = :erlang.unique_integer([:positive, :monotonic])
      valor = "PRJ-" <> Integer.to_string(uniq)
      %__MODULE__{valor: valor}
    end
  end
end
