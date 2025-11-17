defmodule Domain.Chat.ServidorChat do
  @moduledoc """
  Servidor de chat simplificado sin PubSub.
  Utiliza GenServer para mantener el estado de las salas de chat.
  """
  use GenServer
  alias Mensaje

  # ETS table para almacenar mensajes y suscripciones
  @messages_table :chat_messages
  @subscriptions_table :chat_subscriptions

  # API del servidor

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Envía un mensaje al canal correspondiente según su tipo.
  """
  def enviar_mensaje(%Mensaje{} = mensaje) do
    if Mensaje.valido?(mensaje) do
      GenServer.cast(__MODULE__, {:enviar_mensaje, mensaje})
      {:ok, mensaje}
    else
      {:error, :mensaje_invalido}
    end
  end

  @doc """
  Suscribe a un participante a los canales que le corresponden.
  """
  def suscribir_participante(participante_id, equipo_id, temas_interes) do
    GenServer.cast(__MODULE__, {:suscribir_participante, participante_id, equipo_id, temas_interes})
  end

  @doc """
  Obtiene el historial de mensajes para un canal específico.
  """
  def obtener_historial(tipo, id, limit \\ 100) do
    GenServer.call(__MODULE__, {:obtener_historial, tipo, id, limit})
  end

  # Callbacks del GenServer

  @impl true
  def init(_) do
    # Crear tablas ETS para mensajes y suscripciones
    :ets.new(@messages_table, [:set, :public, :named_table])
    :ets.new(@subscriptions_table, [:set, :public, :named_table])
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:enviar_mensaje, mensaje}, state) do
    # Almacenar mensaje en ETS
    topic = case mensaje do
      %{tipo: :anuncio} -> "anuncios"
      %{tipo: :equipo, equipo_id: equipo_id} -> "equipo:#{equipo_id}"
      %{tipo: :sala_tematica, sala_tematica_id: sala_id} -> "sala:#{sala_id}"
    end

    # Guardar mensaje en ETS
    key = {topic, mensaje.fecha_hora}
    :ets.insert(@messages_table, {key, mensaje})

    # Notificar a suscriptores (simplificado)
    notify_subscribers(topic, mensaje)

    {:noreply, state}
  end

  def handle_cast({:suscribir_participante, participante_id, equipo_id, temas_interes}, state) do
    # Suscribir a anuncios generales
    :ets.insert(@subscriptions_table, {{participante_id, "anuncios"}, true})

    # Suscribir al canal del equipo
    if equipo_id do
      :ets.insert(@subscriptions_table, {{participante_id, "equipo:#{equipo_id}"}, true})
    end

    # Suscribir a salas temáticas de interés
    for tema <- temas_interes || [] do
      :ets.insert(@subscriptions_table, {{participante_id, "sala:#{tema}"}, true})
    end

    {:noreply, Map.put(state, participante_id, %{equipo: equipo_id, temas: temas_interes})}
  end

  @impl true
  def handle_call({:obtener_historial, tipo, id, limit}, _from, state) do
    topic = case tipo do
      :anuncio -> "anuncios"
      :equipo -> "equipo:#{id}"
      :sala_tematica -> "sala:#{id}"
      _ -> "unknown"
    end

    # Obtener mensajes de ETS
    mensajes = case :ets.match_object(@messages_table, {{topic, :"$1"}, :"$2"}) do
      [] -> []
      matches ->
        matches
        |> Enum.map(fn {{_key, _timestamp}, mensaje} -> mensaje end)
        |> Enum.sort_by(& &1.fecha_hora, :desc)
        |> Enum.take(limit)
    end

    {:reply, {:ok, mensajes}, state}
  end

  # Función auxiliar para notificar a suscriptores
  defp notify_subscribers(topic, mensaje) do
    # Obtener todos los suscriptores del tópico
    case :ets.match_object(@subscriptions_table, {{:"$1", topic}, true}) do
      [] -> :ok
      subscribers ->
        # En una implementación real, aquí se enviaría el mensaje a cada suscriptor
        # Por ahora, solo lo almacenamos
        :ok
    end
  end
end
