defmodule Adapters.Persistence.RepoBehavior do
  #Crud participantes
  @callback save_participant(participant :: map()) :: :ok
  @callback get_participant(id :: String.t()) :: map() | nil
  @callback list_participants() :: [map()]

  #Crued equipos
  @callback save_team(team :: map()) :: :ok
  @callback get_team(id :: String.t()) :: map() | nil
  @callback list_teams() :: [map()]

  #Crud proyectos
  @callback save_project(project :: map()) :: :ok
  @callback get_project(id :: String.t()) :: map() | nil
  @callback list_projects() :: [map()]
  @callback get_project_by_team(team_id :: String.t()) :: map() | nil

  #Crud mentores
  @callback save_mentor(mentor :: map()) :: :ok
  @callback get_mentor(id :: String.t()) :: map() | nil
  @callback list_mentors() :: [map()]

  #Crud mensajes por equipo
  @callback save_message(team_id :: String.t(), msg :: map()) :: :ok
  @callback list_messages(team_id :: String.t()) :: [map()]

  #Canal general
  @callback save_global_message(msg :: map()) :: :ok
  @callback list_global_messages() :: [map()]

  #Anuncios
  @callback save_announcement(announcement :: map()) :: :ok
  @callback list_announcements(limit :: integer()) :: [map()]
end
