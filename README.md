# 2048 en Flutter

Proyecto de Pau y Chava para **Acceso a datos** (sqflite + shared_preferences) y **Desarrollo de interfaces** (pantallas, navegación, gestos y widgets propios).

## Ejecutar el proyecto

```bash
flutter create . --platforms=android   # genera la carpeta android/ si no existe
flutter pub get
flutter run                            # en emulador o dispositivo Android
flutter test                           # tests de la lógica del juego
```

> Si `flutter create .` crea `test/widget_test.dart`, hay que borrarlo: usa `MyApp`, que aquí no existe.

> sqflite no funciona en web sin configuración extra, así que mejor usar un emulador Android.

## Estructura de carpetas

```
lib/
├── main.dart            # Arranque: carga preferencias y sesión antes de runApp
├── app.dart             # MaterialApp (theme, darkTheme, themeMode, rutas)
├── routes.dart          # Rutas con nombre centralizadas (onGenerateRoute)
├── models/              # Clases modelo con toMap()/fromMap()
├── data/                # DatabaseHelper (singleton) y DAOs
├── services/            # PreferenciasService, AuthService
├── state/               # TemaController, SesionController, AppScope
├── game/                # Lógica pura del 2048 (sin Flutter)
├── theme/               # app_theme.dart: colores, tamaños, espaciados
├── screens/             # Una pantalla por archivo
├── widgets/             # Widgets reutilizables, uno por archivo
└── utils/               # Formateo de fechas y duraciones
```

## Ramas de Git

- `main`: versión que se entrega.
- `develop`: rama de integración.
- `pau/*` y `chava/*`: una rama por tarea que se fusiona en `develop` con `--no-ff`.

Documentación: carpeta [`docs/`](docs/).
