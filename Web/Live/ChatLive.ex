defmodule Web.Live.ChatLive do
  @moduledoc """
  LiveView para la interfaz de chat en tiempo real.
  """
  use Phoenix.LiveView
  use Phoenix.HTML
  
  alias Domain.Chat
  alias Domain.Value_objects.{ID_equipo, ID_participante}
  
  @impl true
  def mount(_params, %{"usuario" => usuario, "equipo_id" => equipo_id} = _session, socket) do
    # Inicializar el estado del socket
    if connected?(socket) do
      # Suscribir al participante a los canales relevantes
      temas_interes = usuario.temas_interes || []
      :ok = Chat.suscribir_participante(usuario.id, equipo_id, temas_interes)
      
      # Suscribirse a los mensajes en tiempo real
      Phoenix.PubSub.subscribe(Domain.PubSub, "chat:anuncios")
      Phoenix.PubSub.subscribe(Domain.PubSub, "chat:equipo:#{equipo_id}")
      
      # Suscribirse a las salas temáticas de interés
      for tema <- temas_interes do
        Phoenix.PubSub.subscribe(Domain.PubSub, "chat:sala:#{tema}")
      end
    end
    
    # Obtener el historial de mensajes
    {:ok, historial_equipo} = Chat.obtener_historial(:equipo, equipo_id)
    
    socket = socket
      |> assign(:usuario, usuario)
      |> assign(:equipo_id, equipo_id)
      |> assign(:canal_actual, :equipo)
      |> assign(:canal_id, equipo_id)
      |> assign(:mensaje, "")
      |> assign(:mensajes, Enum.map(historial_equipo, &Chat.formatear_mensaje(&1, usuario)))
      |> assign(:mostrar_salas, false)
      
    {:ok, socket}
  end
  
  @impl true
  def handle_event("enviar_mensaje", %{"mensaje" => contenido}, socket) do
    if String.trim(contenido) != "" do
      mensaje_id = Ecto.UUID.generate()
      
      case socket.assigns.canal_actual do
        :equipo ->
          Chat.enviar_mensaje_equipo(
            mensaje_id,
            contenido,
            %ID_participante{id: socket.assigns.usuario.id},
            %ID_equipo{id: socket.assigns.equipo_id}
          )
          
        :sala_tematica ->
          Chat.enviar_mensaje_sala_tematica(
            mensaje_id,
            contenido,
            %ID_participante{id: socket.assigns.usuario.id},
            socket.assigns.canal_id
          )
      end
      
      {:noreply, assign(socket, mensaje: "")}
    else
      {:noreply, socket}
    end
  end
  
  @impl true
  def handle_event("cambiar_canal", %{"tipo" => tipo, "id" => id}, socket) do
    # Cambiar al canal seleccionado
    {:ok, historial} = Chat.obtener_historial(String.to_existing_atom(tipo), id)
    
    {:noreply, socket
      |> assign(:canal_actual, String.to_existing_atom(tipo))
      |> assign(:canal_id, id)
      |> assign(:mensajes, Enum.map(historial, &Chat.formatear_mensaje(&1, socket.assigns.usuario)))}
  end
  
  @impl true
  def handle_event("toggle_salas", _, socket) do
    {:noreply, assign(socket, :mostrar_salas, !socket.assigns.mostrar_salas)}
  end
  
  @impl true
  def handle_info({:nuevo_mensaje, mensaje}, socket) do
    # Solo añadir el mensaje si es del canal actual
    mensaje_del_canal = case socket.assigns.canal_actual do
      :equipo -> mensaje.tipo == :equipo && mensaje.equipo_id == socket.assigns.equipo_id
      :sala_tematica -> mensaje.tipo == :sala_tematica && mensaje.sala_tematica_id == socket.assigns.canal_id
      :anuncio -> mensaje.tipo == :anuncio
    end
    
    if mensaje_del_canal do
      mensaje_formateado = Chat.formatear_mensaje(mensaje, socket.assigns.usuario)
      {:noreply, update(socket, :mensajes, &(&1 ++ [mensaje_formateado]))}
    else
      {:noreply, socket}
    end
  end
  
  # Renderizado de la interfaz de chat
  
  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-screen bg-gray-100">
      <!-- Barra lateral -->
      <div class="w-64 bg-white border-r border-gray-200">
        <div class="p-4 border-b border-gray-200">
          <h2 class="text-lg font-semibold">Canales</h2>
        </div>
        
        <div class="p-2">
          <button 
            phx-click="cambiar_canal" 
            phx-value-tipo="anuncio"
            class={"w-full text-left px-4 py-2 rounded hover:bg-gray-100", 
                   "bg-blue-100 font-medium": @canal_actual == :anuncio}">
            📢 Anuncios
          </button>
          
          <button 
            phx-click="cambiar_canal" 
            phx-value-tipo="equipo" 
            phx-value-id={@equipo_id}
            class={"w-full text-left px-4 py-2 rounded hover:bg-gray-100 mt-1",
                   "bg-blue-100 font-medium": @canal_actual == :equipo}>
            👥 Equipo
          </button>
          
          <div class="mt-4">
            <div class="flex justify-between items-center px-4 py-2">
              <span class="text-sm font-medium text-gray-500">Salas Temáticas</span>
              <button phx-click="toggle_salas" class="text-gray-400 hover:text-gray-600">
                <%= if @mostrar_salas, do: "-", else: "+" %>
              </button>
            </div>
            
            <%= if @mostrar_salas do %>
              <div class="pl-4">
                <%= for sala <- @usuario.temas_interes || [] do %>
                  <button 
                    phx-click="cambiar_canal" 
                    phx-value-tipo="sala_tematica" 
                    phx-value-id={sala}
                    class={"w-full text-left px-4 py-1 text-sm rounded hover:bg-gray-100",
                           "bg-blue-50 font-medium": @canal_actual == :sala_tematica && @canal_id == sala}>
                    # <%= sala %>
                  </button>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
      
      <!-- Área de chat principal -->
      <div class="flex-1 flex flex-col">
        <!-- Cabecera del chat -->
        <div class="p-4 border-b border-gray-200 bg-white">
          <h1 class="text-xl font-semibold">
            <%= case @canal_actual do %>
              :anuncio -> "📢 Anuncios"
              :equipo -> "👥 Chat del equipo"
              :sala_tematica -> "##{@canal_id}"
            end %>
          </h1>
        </div>
        
        <!-- Mensajes -->
        <div class="flex-1 overflow-y-auto p-4 space-y-4" id="mensajes">
          <%= for mensaje <- @mensajes do %>
            <div class={"flex mb-4", "justify-end": mensaje.remitente_id == @usuario.id}>
              <div class={"max-w-xs lg:max-w-md px-4 py-2 rounded-lg", 
                         "bg-blue-500 text-white": mensaje.remitente_id == @usuario.id,
                         "bg-white border border-gray-200": mensaje.remitente_id != @usuario.id}>
                <div class="text-sm font-medium">
                  <%= if mensaje.remitente_id == @usuario.id do %>
                    Tú
                  <% else %>
                    <%= mensaje.remitente %>
                  <% end %>
                </div>
                <div class="text-sm"><%= mensaje.contenido %></div>
                <div class="text-xs opacity-70 mt-1"><%= mensaje.fecha_hora %></div>
              </div>
            </div>
          <% end %>
        </div>
        
        <!-- Entrada de mensaje -->
        <div class="p-4 border-t border-gray-200 bg-white">
          <form phx-submit="enviar_mensaje" class="flex space-x-2">
            <input 
              type="text" 
              name="mensaje" 
              value={@mensaje}
              placeholder="Escribe un mensaje..." 
              class="flex-1 border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500"
              phx-hook="AutoScroll"
            />
            <button 
              type="submit" 
              class="bg-blue-500 text-white px-6 py-2 rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500">
              Enviar
            </button>
          </form>
        </div>
      </div>
    </div>
    
    <!-- JavaScript para auto-desplazamiento -->
    <script>
      let Hooks = {}
      Hooks.AutoScroll = {
        mounted() {
          this.el.addEventListener("phx:update", () => {
            const messages = document.getElementById("mensajes");
            messages.scrollTop = messages.scrollHeight;
          });
        }
      }
      
      let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket, {
        hooks: Hooks,
        params: {_csrf_token: "<%= get_csrf_token() %>"}
      });
      window.liveSocket = liveSocket;
    </script>
    """
  end
end
