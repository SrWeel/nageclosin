# Nageclosin Notes App

Aplicación móvil para la gestión de notas personales.  
La aplicación está enfocada en una experiencia de usuario clara, navegación simple entre pantallas y persistencia local de datos.

---

## Descripción de la Aplicación

Nageclosin Notes es una aplicación móvil que permite a los usuarios crear, editar, visualizar y eliminar notas de manera sencilla.

La aplicación implementa navegación entre una pantalla principal que muestra la lista de notas y una pantalla de detalle donde se pueden crear o editar notas.

El objetivo del proyecto es demostrar buenas prácticas de desarrollo móvil incluyendo arquitectura organizada, actualización reactiva de la interfaz y almacenamiento local de información.

---

## Objetivo del Proyecto

Desarrollar una aplicación de notas que implemente navegación entre:

[ Pantalla Lista de Notas ] <-> [ Pantalla Detalle / Edición ]

Este proyecto evalúa:

• Diseño de interfaz de usuario (UI)  
• Experiencia de usuario (UX)  
• Persistencia de datos local  
• Separación de responsabilidades en la arquitectura  
• Navegación entre pantallas  
• Buen uso de control de versiones con Git

---

## Funcionalidades Principales

### Lista de Notas

- Visualización de todas las notas almacenadas
- Ordenadas por fecha de actualización
- Posibilidad de marcar notas como importantes (pinned)
- Acceso rápido para editar notas
- Botón flotante para crear una nueva nota

### Detalle / Edición de Nota

- Campo editable para el título
- Campo editable para el contenido
- Creación de nuevas notas
- Edición de notas existentes
- Guardado automático al regresar a la lista

### Navegación

- Navegación segura entre pantallas
- Paso de datos entre la lista y el detalle
- Manejo correcto del historial de navegación

### Persistencia de Datos

- Almacenamiento local usando SQLite
- Las notas permanecen guardadas incluso después de cerrar la aplicación

### Validaciones

- El título de la nota no puede estar vacío
- Confirmación antes de eliminar una nota
- Mensajes de retroalimentación al usuario

---

## UX / UI

El diseño de la interfaz sigue principios de usabilidad y claridad visual.

Características de la interfaz:

- Diseño limpio y minimalista
- Jerarquía visual clara
- Uso de tarjetas para mostrar notas
- Botón flotante para la acción principal
- Interfaz adaptable a distintos tamaños de pantalla
- Preservación del estado en rotación de pantalla

---

## Tecnologías Utilizadas

| Capa | Tecnología |
|-----|-------------|
| Framework móvil | Flutter |
| Lenguaje | Dart |
| Arquitectura | MVVM |
| Gestión de estado | ViewModel |
| Base de datos local | SQLite |
| Navegación | Flutter Navigation |
| Control de versiones | Git |

---

## Arquitectura del Proyecto

El proyecto utiliza una arquitectura basada en **MVVM (Model - View - ViewModel)**.

```
Interfaz de Usuario (Screens / Widgets)
              |
              v
ViewModel (Estado y lógica de negocio)
              |
              v
Repositorio de Datos
              |
              v
Base de Datos Local (SQLite)
```

### Responsabilidades

**UI (View)**  
Encargada de mostrar los datos y manejar la interacción del usuario.

**ViewModel**  
Gestiona el estado de la aplicación y la lógica de negocio.

**Repositorio**  
Actúa como intermediario entre la aplicación y la base de datos.

**Base de Datos**  
Almacena las notas de forma local.

---

## Modelo de Datos

Entidad principal: `Note`

```
Note
 ├── id
 ├── title
 ├── content
 ├── createdAt
 ├── updatedAt
 └── isPinned
```

---

## Estructura del Proyecto

```
lib
│
├── models
│   └── note.dart
│
├── database
│   └── notes_database.dart
│
├── repositories
│   └── notes_repository.dart
│
├── viewmodels
│   └── notes_viewmodel.dart
│
├── screens
│   ├── notes_list_screen.dart
│   └── note_detail_screen.dart
│
├── widgets
│   └── note_card.dart
│
└── main.dart
```

---

## Requisitos Funcionales Implementados

✔ Crear notas  
✔ Editar notas  
✔ Eliminar notas  
✔ Mostrar lista de notas  
✔ Navegación entre pantallas  
✔ Persistencia de datos local  

---

## Funcionalidades Opcionales

Mejoras adicionales posibles:

- Búsqueda de notas
- Filtro de notas
- Notas fijadas (pinned)
- Exportar / importar notas en JSON
- Pruebas unitarias

---

## Instalación y Ejecución

1. Clonar el repositorio

```
git clone https://github.com/usuario/repositorio.git
```

2. Entrar al proyecto

```
cd nageclosin
```

3. Instalar dependencias

```
flutter pub get
```

4. Ejecutar la aplicación

```
flutter run
```

---

## Generar APK

Para generar el archivo de instalación:

```
flutter build apk
```

El archivo se generará en:

```
build/app/outputs/flutter-apk/
```

---

## Entregables del Proyecto

El repositorio incluye:

- Código fuente completo
- Archivo README.md
- Historial de commits
- APK de la aplicación
- Video demostrativo

---

## Video Demostrativo

El video muestra:

- Creación de notas
- Edición de notas
- Eliminación de notas
- Navegación entre pantallas
- Persistencia de datos después de reiniciar la aplicación
---

## Notas de Desarrollo

Durante el desarrollo se priorizó:

- Separación clara de responsabilidades
- Código mantenible
- Interfaz intuitiva
- Arquitectura escalable

Como mejoras futuras se podría integrar sincronización en la nube y funciones avanzadas de búsqueda.
