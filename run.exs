# run.exs
# Ejecutar con: elixir run.exs

IO.puts("🔄 Cargando módulos del sistema...")

# ============================================================================
# CARGAR MÓDULOS DEL DOMAIN
# ============================================================================
Code.require_file("Domain/participante.ex", __DIR__)
Code.require_file("Domain/equipo.ex", __DIR__)
Code.require_file("Domain/proyecto.ex", __DIR__)
Code.require_file("Domain/mensaje.ex", __DIR__)
Code.require_file("Domain/mentor.ex", __DIR__)

# ============================================================================
# CARGAR ADAPTADORES - PERSISTENCE
# ============================================================================
Code.require_file("Adapters/Persistence/ets_repo.ex", __DIR__)

# ============================================================================
# CARGAR SERVICIOS
# ============================================================================
Code.require_file("Services/equipo_service.ex", __DIR__)
Code.require_file("Services/proyecto_service.ex", __DIR__)
Code.require_file("Services/chat_service.ex", __DIR__)
Code.require_file("Services/mentor_service.ex", __DIR__)

# ============================================================================
# CARGAR ADAPTADORES - CLI
# ============================================================================
Code.require_file("Adapters/CLI/command_handler.ex", __DIR__)
Code.require_file("Adapters/CLI/interface.ex", __DIR__)

IO.puts("✅ Módulos cargados correctamente\n")

# ============================================================================
# INICIAR LA APLICACIÓN
# ============================================================================
Adapters.CLI.Interface.start()
