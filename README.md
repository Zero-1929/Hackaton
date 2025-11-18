# 🚀 Hackathon Code4Future - Sistema de Gestión

Sistema completo de gestión para hackathons desarrollado en Elixir con arquitectura hexagonal.

## 📋 Tabla de Contenidos

- [Características](#características)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Ejecución](#ejecución)
- [Comandos Disponibles](#comandos-disponibles)
- [Arquitectura](#arquitectura)
- [Estructura del Proyecto](#estructura-del-proyecto)

---

## ✨ Características

### Funcionalidades Principales

✅ **Gestión de Equipos**
- Registro de participantes
- Creación de equipos por categoría
- Asignación de miembros a equipos
- Listado de equipos activos

✅ **Gestión de Proyectos**
- Registro de ideas con descripción y categoría
- Actualización de avances en tiempo real
- Consulta por categoría o estado
- Cálculo automático de progreso

✅ **Comunicación en Tiempo Real**
- Sistema de mensajería por equipo
- Canal general para anuncios
- Salas temáticas de discusión
- Historial de mensajes

✅ **Sistema de Mentoría**
- Registro de mentores con especialidades
- Canal de consultas equipo-mentor
- Retroalimentación almacenada
- Gestión de disponibilidad

✅ **Requisitos No Funcionales**
- ✅ Escalabilidad con procesos concurrentes (GenServer)
- ✅ Alto rendimiento con ETS
- ✅ Tolerancia a fallos con supervisión OTP
- ✅ Persistencia en memoria con ETS

---

## 📦 Requisitos

- **Elixir**: versión 1.14 o superior
- **Erlang/OTP**: versión 25 o superior

### Verificar instalación

```bash
elixir --version
# Elixir 1.14.x (compiled with Erlang/OTP 25)
```

### Instalación de Elixir

**macOS:**
```bash
brew install elixir
```

**Ubuntu/Debian:**
```bash
sudo apt-get install elixir
```

**Windows:**
- Descargar desde: https://elixir-lang.org/install.html

---

## 🚀 Instalación

### 1. Clonar o descargar el proyecto

```bash
git clone <url-del-repositorio>
cd hackathon_app
```

### 2. Verificar estructura de archivos

```
hackathon_app/
├── Domain/
│   ├── participante.ex
│   ├── equipo.ex
│   ├── proyecto.ex
│   ├── mensaje.ex
│   └── mentor.ex
├── Services/
│   ├── equipo_service.ex
│   ├── proyecto_service.ex
│   ├── chat_service.ex
│   └── mentor_service.ex
├── Adapters/
│   ├── Persistence/
│   │   └── ets_repo.ex
│   └── CLI/
│       ├── command_handler.ex
│       └── interface.ex
├── run.exs
└── README.md
```

---

## ▶️ Ejecución

### Método 1: Ejecución directa (Recomendado)

```bash
elixir run.exs
```

### Método 2: Consola interactiva

```bash
iex run.exs
```

---

## 🎮 Comandos Disponibles

### Comandos Principales

| Comando | Descripción | Ejemplo |
|---------|-------------|---------|
| `/help` | Muestra la ayuda completa | `/help` |
| `/teams` | Lista todos los equipos | `/teams` |
| `/join <equipo>` | Únete a un equipo | `/join Code Masters` |
| `/project <equipo>` | Ver proyecto del equipo | `/project Code Masters` |
| `/chat <equipo>` | Abrir chat del equipo | `/chat Code Masters` |
| `/quit` | Salir de la aplicación | `/quit` |

### Ejemplos de Uso

```bash
# 1. Listar equipos disponibles
hackathon> /teams

# 2. Ver proyecto de un equipo
hackathon> /project Code Masters

# 3. Unirse a un equipo
hackathon> /join Code Masters

# 4. Abrir chat de equipo
hackathon> /chat Code Masters
> Hola equipo!
> ¿Cómo va el proyecto?
> /exit

# 5. Salir
hackathon> /quit
```

---

## 🏗️ Arquitectura

### Patrón: Arquitectura Hexagonal (Puertos y Adaptadores)

```
┌─────────────────────────────────────────────────────────┐
│                     ADAPTERS (CLI)                      │
│                  Interface & Commands                   │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                      SERVICES                           │
│      Orquestación y Casos de Uso de Aplicación         │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                      DOMAIN                             │
│     Lógica de Negocio Pura (Entidades)                 │
│  Participante | Equipo | Proyecto | Mensaje | Mentor   │
└─────────────────────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              ADAPTERS (Persistence)                     │
│                    ETSRepo (ETS)                        │
└─────────────────────────────────────────────────────────┘
```

### Ventajas de esta Arquitectura

1. **Separación de responsabilidades**: Cada capa tiene un propósito claro
2. **Independencia de la infraestructura**: El dominio no depende de ETS
3. **Testeable**: Cada capa se puede probar independientemente
4. **Mantenible**: Cambios localizados en cada capa
5. **Escalable**: Fácil agregar nuevas funcionalidades

---

## 📁 Estructura del Proyecto

### Domain (Capa de Dominio)

**Responsabilidad**: Lógica de negocio pura, sin dependencias externas

- **participante.ex**: Entidad Participante con validaciones
- **equipo.ex**: Entidad Equipo con gestión de miembros
- **proyecto.ex**: Entidad Proyecto con estados y avances
- **mensaje.ex**: Entidad Mensaje para el sistema de chat
- **mentor.ex**: Entidad Mentor con consultas y feedback

### Services (Capa de Servicios)

**Responsabilidad**: Orquestación de casos de uso

- **equipo_service.ex**: Crear equipos, unir participantes
- **proyecto_service.ex**: Crear proyectos, actualizar avances
- **chat_service.ex**: Enviar mensajes, gestionar historial
- **mentor_service.ex**: Registrar mentores, consultas, feedback

### Adapters (Capa de Adaptadores)

**Responsabilidad**: Conexión con el mundo exterior

#### Persistence
- **ets_repo.ex**: Repositorio usando ETS (Erlang Term Storage)

#### CLI
- **interface.ex**: Interfaz principal, loop de entrada
- **command_handler.ex**: Procesamiento de comandos

---

## 🗄️ Persistencia con ETS

El sistema utiliza **ETS (Erlang Term Storage)** para almacenamiento en memoria:

### Tablas ETS Creadas

| Tabla | Contenido | Clave |
|-------|-----------|-------|
| `:participantes_table` | Participantes | ID |
| `:equipos_table` | Equipos | ID |
| `:proyectos_table` | Proyectos | ID |
| `:mentores_table` | Mentores | ID |
| `:mensajes_table` | Mensajes | {tipo, destino, timestamp} |
| `:salas_tematicas_table` | Salas | ID |

### Características de ETS

✅ **Rápido**: Acceso en O(1) para búsquedas  
✅ **Concurrente**: Múltiples procesos pueden leer simultáneamente  
✅ **Simple**: No requiere base de datos externa  
⚠️ **Volátil**: Los datos se pierden al cerrar la aplicación

---

## 🧪 Datos de Ejemplo

Al iniciar, el sistema carga automáticamente:

### Participantes (5)
- Ana García
- Carlos López  
- María Rodríguez
- Juan Pérez
- Laura Martínez

### Equipos (3)
1. **Code Masters** (Desarrollo Web) - 2 miembros
2. **Data Wizards** (Machine Learning) - 2 miembros
3. **Mobile Heroes** (Apps Móviles) - 1 miembro

### Proyectos (3)
1. **Plataforma Educativa Online** (Code Masters)
2. **Predictor de Clima** (Data Wizards)
3. **App de Reciclaje** (Mobile Heroes)

### Mentores (3)
- Dr. Roberto Sánchez (Backend, BD, Arquitectura)
- Dra. Patricia Gómez (ML, Python, Data Science)
- Ing. Miguel Torres (Mobile, UX/UI, React Native)

### Salas Temáticas (3)
- Backend
- Frontend
- DevOps

---

## 🔧 Solución de Problemas

### Error: "module not found"

```bash
# Asegúrate de estar en el directorio correcto
cd hackathon_app

# Verifica que todos los archivos existan
ls Domain/
ls Services/
ls Adapters/
```

### Error: "table already exists"

```bash
# Normal al reiniciar, el código lo maneja automáticamente
# No es un error crítico
```

### Error de sintaxis

```bash
# Verifica la versión de Elixir
elixir --version

# Debe ser >= 1.14
```

---

## 📚 Documentación Adicional

- [Guía de Elixir](https://elixir-lang.org/getting-started/introduction.html)
- [GenServer](https://elixir-lang.org/getting-started/mix-otp/genserver.html)
- [ETS Documentation](https://www.erlang.org/doc/man/ets.html)

---

## 👥 Equipo de Desarrollo

Proyecto desarrollado para el curso de Programación III

**Institución**: [Tu Universidad]  
**Fecha**: Noviembre 2025  
**Hackathon**: Code4Future 2025

---

## 📄 Licencia

Proyecto académico - Todos los derechos reservados

---

**¿Listo para gestionar tu hackathon?** 🚀

Ejecuta `elixir run.exs` y comienza a explorar el sistema.