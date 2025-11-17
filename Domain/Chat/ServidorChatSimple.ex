defmodule Domain.Chat.ServidorChat do
  @moduledoc """
  Versión simplificada del servidor de chat que funciona con ETS.
  Gestiona los mensajes y suscripciones sin dependencias externas.
  """

  use GenServer
  alias Domain.Mensaje
  alias Adapters.Persistence.ETSRepo

  # Tablas ETS para el chat
  @messages_table :chat_messages
  @subscriptions_table :chat_subscriptions

  # API pública

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Envía un mensaje al canal correspondiente.
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
  Suscribe a un participante a los canales relevantes.
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

  # Callbacks de GenServer

  @impl true
  def init(_) do
    # Crear tablas ETS si no existen
    create_table(@messages_table)
    create_table(@subscriptions_table)

    {:ok, %{}}
  end

  @impl true
  def handle_cast({:enviar_mensaje, mensaje}, state) do
    # Guardar el mensaje en la tabla apropiada
    case mensaje.tipo do
      :anuncio ->
        ETSRepo.save_global_message(mensaje)

      :equipo ->
        if mensaje.equipo_id do
          ETSRepo.save_message(mensaje.equipo_id.valor, mensaje)
        end

      :sala_tematica ->
        if mensaje.sala_tematica_id do
          ETSRepo.save_message("sala_#{mensaje.sala_tematica_id}", mensaje)
        end
    end

    # Notificar a los suscriptores (implementación simple)
    notificar_suscriptores(mensaje)

    {:noreply, state}
  end

  def handle_cast({:suscribir_participante, participante_id, equipo_id, temas_interes}, state) do
    # Guardar suscripción del participante
    subscriptions = %{
      participante_id: participante_id.valor,
      equipo_id: if(equipo_id, do: equipo_id.valor, else: nil),
      temas_interes: temas_interes || []
    }

    :ets.insert(@subscriptions_table, {participante_id.valor, subscriptions})

    {:noreply, state}
  end

  @impl true
  def handle_call({:obtener_historial, tipo, id, limit}, _from, state) do
    historial = case tipo do
      :anuncio ->
        ETSRepo.list_global_messages()

      :equipo ->
        if id do
          ETSRepo.list_messages(id.valor)
        else
          []
        end

      :sala_tematica ->
        if id do
          ETSRepo.list_messages("sala_#{id}")
        else
          []
        end
    end

    # Aplicar límite
    historial_limitado = Enum.take(historial, limit)

    {:reply, {:ok, historial_limitado}, state}
  end

  # Funciones privadas

  defp create_table(name) do
    :ets.new(name, [:named_table, :set, :public, read_concurrency: true])
  rescue
    _ -> :ok  # La tabla ya existe
  end

  defp notificar_suscriptores(mensaje) do
    # Implementación simple de notificación
    # En una versión real, esto enviaría los mensajes a los clientes conectados
    IO.puts("📢 Nuevo mensaje #{mensaje.tipo}: #{mensaje.contenido}")
  end
end
