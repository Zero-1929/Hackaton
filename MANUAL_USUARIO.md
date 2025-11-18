# 📖 Manual de Usuario
## Sistema de Gestión de Hackathon Code4Future

---

## Índice

1. [Introducción](#introducción)
2. [Inicio Rápido](#inicio-rápido)
3. [Guía de Comandos](#guía-de-comandos)
4. [Casos de Uso Comunes](#casos-de-uso-comunes)
5. [Preguntas Frecuentes](#preguntas-frecuentes)

---

## 1. Introducción

### ¿Qué es este sistema?

El Sistema de Gestión de Hackathon Code4Future es una aplicación de línea de comandos que permite:

- 👥 Gestionar equipos y participantes
- 📊 Registrar y dar seguimiento a proyectos
- 💬 Comunicarse en tiempo real
- 🎓 Conectar con mentores
- 📢 Recibir anuncios importantes

### ¿Quién puede usar el sistema?

- **Participantes**: Pueden unirse a equipos, ver proyectos y chatear
- **Organizadores**: Pueden crear equipos, proyectos y enviar anuncios
- **Mentores**: Pueden dar retroalimentación y responder consultas

---

## 2. Inicio Rápido

### Paso 1: Abrir el programa

```bash
elixir run.exs
```

### Paso 2: Verás la pantalla de bienvenida

```
╔══════════════════════════════════════════════════════════════╗
║              🚀 HACKATHON CODE4FUTURE 2025 🚀                ║
║                                                              ║
║  Sistema de Gestión de Hackathon Colaborativa               ║
╚══════════════════════════════════════════════════════════════╝

👤 Bienvenido, Organizador!

hackathon>
```

### Paso 3: Escribe tu primer comando

```bash
hackathon> /help
```

---

## 3. Guía de Comandos

### 3.1. Ver Equipos Disponibles

**Comando**: `/teams`

**Qué hace**: Muestra todos los equipos registrados en la hackathon

**Ejemplo**:

```bash
hackathon> /teams

╔══════════════════════════════════════════════════════════════╗
║                    🏆 EQUIPOS REGISTRADOS                    ║
╚══════════════════════════════════════════════════════════════╝

📋 Code Masters
   ID: TEAM-1731789123456-1234
   Categoría: Desarrollo Web
   Miembros: 2
   Estado: ✅ Activo
────────────────────────────────────────────────────────────

📋 Data Wizards
   ID: TEAM-1731789123457-5678
   Categoría: Machine Learning
   Miembros: 2
   Estado: ✅ Activo
────────────────────────────────────────────────────────────
```

**Uso típico**:
- Al iniciar, para ver qué equipos existen
- Antes de unirte a un equipo
- Para verificar la información de tu equipo

---

### 3.2. Unirse a un Equipo

**Comando**: `/join <nombre_del_equipo>`

**Qué hace**: Te une como participante a un equipo existente

**Ejemplo**:

```bash
hackathon> /join Code Masters

✅ Te has unido exitosamente al equipo 'Code Masters'!
```

**Errores comunes**:

```bash
# Si el equipo no existe
❌ No existe un equipo con el nombre 'Equipo Inexistente'.

# Si ya eres miembro
⚠️  Ya eres miembro del equipo 'Code Masters'.
```

**Nota importante**: Debes escribir el nombre EXACTO del equipo (respeta mayúsculas y espacios)

---

### 3.3. Ver Proyecto de un Equipo

**Comando**: `/project <nombre_del_equipo>`

**Qué hace**: Muestra la información completa del proyecto de un equipo

**Ejemplo**:

```bash
hackathon> /project Code Masters

╔══════════════════════════════════════════════════════════════╗
║              📌 PROYECTO DEL EQUIPO Code Masters            ║
╚══════════════════════════════════════════════════════════════╝

Nombre:      Plataforma Educativa Online
Categoría:   Educación
Descripción: Sistema web para aprendizaje colaborativo
Estado:      en_progreso
Progreso:    55%

--- ÚLTIMOS AVANCES ---
  • [17/11/2025 14:30:00] Mockups de UI listos
  • [17/11/2025 12:15:00] Definición de arquitectura completada
```

**Información mostrada**:
- ✅ Nombre del proyecto
- ✅ Categoría temática
- ✅ Descripción completa
- ✅ Estado actual (nuevo, en_progreso, finalizado)
- ✅ Porcentaje de progreso calculado
- ✅ Últimos 3 avances registrados

**Casos de uso**:
- Ver en qué están trabajando otros equipos
- Revisar el progreso de tu propio equipo
- Preparar presentaciones o demos

---

### 3.4. Abrir Chat de Equipo

**Comando**: `/chat <nombre_del_equipo>`

**Qué hace**: Abre el chat del equipo donde puedes enviar y recibir mensajes

**Ejemplo**:

```bash
hackathon> /chat Code Masters

╔══════════════════════════════════════════════════════════════╗
║           💬 CHAT DEL EQUIPO Code Masters                   ║
╚══════════════════════════════════════════════════════════════╝

[17/11/2025 14:30:45] Ana García: ¿Cómo vamos con el backend?
[17/11/2025 14:32:10] Carlos López: Ya tengo la API lista
[17/11/2025 14:35:20] Ana García: Perfecto, probemos la integración

Escribe tu mensaje (o /exit para salir):

> Excelente trabajo equipo!
[17/11/2025 14:36:00] Organizador: Excelente trabajo equipo!
> Reunión en 10 minutos
[17/11/2025 14:36:30] Organizador: Reunión en 10 minutos
> /exit

👋 Saliendo del chat...

hackathon>
```

**Cómo funciona**:
1. Muestra los últimos 20 mensajes del equipo
2. Puedes escribir mensajes libremente
3. Tus mensajes aparecen instantáneamente
4. Escribe `/exit` para salir del chat

**Consejos**:
- ✅ Usa el chat para coordinar con tu equipo
- ✅ Comparte enlaces y recursos
- ✅ Pregunta dudas técnicas
- ❌ No uses el chat para spam

---

### 3.5. Ver Ayuda

**Comando**: `/help`

**Qué hace**: Muestra todos los comandos disponibles

**Ejemplo**:

```bash
hackathon> /help

╔══════════════════════════════════════════════════════════════╗
║                   📋 COMANDOS DISPONIBLES                    ║
╚══════════════════════════════════════════════════════════════╝

COMANDOS PRINCIPALES:
  /teams                  → Lista todos los equipos registrados
  /join <equipo>          → Únete a un equipo
  /project <equipo>       → Muestra el proyecto de un equipo
  /chat <equipo>          → Abre el chat de un equipo
  /help                   → Muestra esta ayuda
  /quit                   → Sale de la aplicación
```

---

### 3.6. Salir del Sistema

**Comando**: `/quit`

**Qué hace**: Cierra la aplicación de forma segura

**Ejemplo**:

```bash
hackathon> /quit

👋 ¡Gracias por participar en Code4Future! Hasta pronto.
```

---

## 4. Casos de Uso Comunes

### 4.1. Escenario: Nuevo Participante

**Situación**: Acabas de llegar a la hackathon y quieres unirte a un equipo

**Pasos**:

```bash
# 1. Ver equipos disponibles
hackathon> /teams

# 2. Elegir un equipo que te interese
#    (Basándote en la categoría)

# 3. Unirte al equipo
hackathon> /join Data Wizards

# 4. Ver el proyecto del equipo
hackathon> /project Data Wizards

# 5. Abrir el chat para presentarte
hackathon> /chat Data Wizards
> Hola! Soy nuevo en el equipo, ¿en qué puedo ayudar?
> /exit
```

---

### 4.2. Escenario: Revisar Progreso de Equipos

**Situación**: Eres organizador y quieres ver cómo van todos los proyectos

**Pasos**:

```bash
# 1. Listar todos los equipos
hackathon> /teams

# 2. Revisar cada proyecto
hackathon> /project Code Masters
hackathon> /project Data Wizards
hackathon> /project Mobile Heroes

# 3. Tomar notas del progreso de cada uno
```

---

### 4.3. Escenario: Coordinar con tu Equipo

**Situación**: Necesitas comunicarte con tu equipo en tiempo real

**Pasos**:

```bash
# 1. Abrir chat del equipo
hackathon> /chat Code Masters

# 2. Escribir mensajes
> Reunión urgente, ¿están disponibles?
> Necesitamos definir la arquitectura
> ¿Alguien puede compartir el repo de GitHub?

# 3. Salir cuando termines
> /exit
```

---

### 4.4. Escenario: Presentar tu Proyecto

**Situación**: Vas a hacer la demo final y necesitas recordar los avances

**Pasos**:

```bash
# 1. Ver información completa del proyecto
hackathon> /project Code Masters

# 2. Revisar:
#    - Descripción del proyecto
#    - Avances registrados
#    - Progreso actual
```

---

## 5. Preguntas Frecuentes

### ¿Puedo estar en varios equipos?

No, cada participante solo puede estar en un equipo a la vez.

---

### ¿Cómo se calcula el progreso del proyecto?

El progreso se calcula automáticamente basándose en:
- Estado del proyecto (nuevo = 0%, en_progreso = variable, finalizado = 100%)
- Cantidad de avances registrados

---

### ¿Puedo ver mensajes antiguos del chat?

Sí, al abrir el chat se muestran los últimos 20 mensajes del equipo.

---

### ¿Qué pasa si escribo mal el nombre de un equipo?

El sistema te dirá que el equipo no existe. Verifica la ortografía exacta con `/teams`.

---

### ¿Los datos se guardan al cerrar el programa?

No, el sistema usa almacenamiento en memoria (ETS). Los datos se pierden al cerrar.

---

### ¿Puedo crear nuevos equipos?

En esta versión no, los equipos son creados por los organizadores al inicio.

---

### ¿Qué hago si el programa no responde?

Presiona `Ctrl+C` dos veces para forzar el cierre y vuelve a ejecutar `elixir run.exs`.

---

## 📞 Soporte

Si tienes problemas técnicos o dudas sobre el uso del sistema:

1. Revisa este manual
2. Usa el comando `/help`
3. Contacta al equipo organizador

---

**¡Disfruta tu hackathon!** 🚀

*Code4Future 2025 - Construyendo el futuro con tecnología*