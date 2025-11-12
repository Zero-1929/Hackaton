defmodule Domain.Chat.ServidorChat do
  @moduledoc """
  Módulo que gestiona los canales de chat y la distribución de mensajes.
  Utiliza GenServer para mantener el estado de las salas de chat.
  """
  use GenServer
  alias Domain.Mensaje
  alias Phoenix.PubSub
  alias Domain.Repo

  # Nombres de tópicos para PubSub
  @topic_anuncios "chat:anuncios"
  @topic_equipo_prefix "chat:equipo:"
  @topic_sala_prefix "chat:sala:"

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
    PubSub.subscribe(Domain.PubSub, @topic_anuncios)
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:enviar_mensaje, mensaje}, state) do
    topic = case mensaje do
      %{tipo: :anuncio} -> @topic_anuncios
      %{tipo: :equipo, equipo_id: equipo_id} -> "#{@topic_equipo_prefix}#{equipo_id}"
      %{tipo: :sala_tematica, sala_tematica_id: sala_id} -> "#{@topic_sala_prefix}#{sala_id}"
    end

    # Publicar el mensaje a los suscriptores del tópico
    PubSub.broadcast(Domain.PubSub, topic, {:nuevo_mensaje, mensaje})
    
    # Persistir el mensaje (implementar según tu base de datos)
    guardar_mensaje(mensaje)
    
    {:noreply, state}
  end

  def handle_cast({:suscribir_participante, participante_id, equipo_id, temas_interes}, state) do
    # Suscribir a anuncios generales
    PubSub.subscribe(Domain.PubSub, @topic_anuncios)
    
    # Suscribir al canal del equipo
    if equipo_id do
      PubSub.subscribe(Domain.PubSub, "#{@topic_equipo_prefix}#{equipo_id}")
    end
    
    # Suscribir a salas temáticas de interés
    for tema <- temas_interes || [] do
      PubSub.subscribe(Domain.PubSub, "#{@topic_sala_prefix}#{tema}")
    end
    
    {:noreply, Map.put(state, participante_id, %{equipo: equipo_id, temas: temas_interes})}
  end

  @impl true
  def handle_call({:obtener_historial, tipo, id, limit}, _from, state) do
    # Implementar la lógica para recuperar el historial de mensajes
    # desde tu base de datos según el tipo y el ID
    historial = case tipo do
      :anuncio -> Repo.all(from m in "mensajes", where: m.tipo == ^:anuncio, limit: ^limit, order_by: [desc: :fecha_hora])
      :equipo -> Repo.all(from m in "mensajes", where: m.tipo == ^:equipo and m.equipo_id == ^id, limit: ^limit, order_by: [desc: :fecha_hora])
      :sala_tematica -> Repo.all(from m in "mensajes", where: m.tipo == ^:sala_tematica and m.sala_tematica_id == ^id, limit: ^limit, order_by: [desc: :fecha_hora])
    end
    
    {:reply, {:ok, Enum.reverse(historial)}, state}
  end

  # Funciones privadas
  
  defp guardar_mensaje(mensaje) do
    # Implementar la lógica para guardar el mensaje en la base de datos
    # Esto es un ejemplo y deberías adaptarlo a tu esquema de base de datos
    Repo.insert("mensajes", %{
      id: mensaje.id,
      contenido: mensaje.contenido,
      remitente_id: mensaje.remitente_id,
      tipo: mensaje.tipo,
      equipo_id: mensaje.equipo_id,
      sala_tematica_id: mensaje.sala_tematica_id,
      fecha_hora: mensaje.fecha_hora,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    })
  end
end
