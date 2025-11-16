# Script de ejecución para la aplicación Hackathon
# Ejecutar con: elixir run.exs

# Cargar todos los módulos necesarios
Code.require_file("Domain/value_objects.ex", __DIR__)
Code.require_file("Domain/Mensaje.ex", __DIR__)
Code.require_file("Domain/Participante.ex", __DIR__)
Code.require_file("Domain/Equipo.ex", __DIR__)
Code.require_file("Domain/Chat/ServidorChat.ex", __DIR__)
Code.require_file("Domain/Chat.ex", __DIR__)

# Cargar adaptadores
Code.require_file("adapters/persistence/repo_behavior.ex", __DIR__)
Code.require_file("adapters/persistence/ets_repo.ex", __DIR__)
Code.require_file("adapters/persistence/memory_repo.ex", __DIR__)
Code.require_file("adapters/cli/command_handler.ex", __DIR__)
Code.require_file("adapters/cli/cli_interface.ex", __DIR__)

# Cargar servicios
Code.require_file("services/team_service.ex", __DIR__)
Code.require_file("services/chat_service.ex", __DIR__)

# Cargar el main
Code.require_file("main.ex", __DIR__)

# Iniciar la aplicación
Main.start()
