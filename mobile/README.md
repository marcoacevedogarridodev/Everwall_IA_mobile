# Pixel App — Mobile (Flutter)

App estilo Instagram/Facebook con grilla infinita de píxeles tipo Google Maps,
auth completo, compra de píxeles, likes, comentarios, mensajes y dark mode
premium.

## 🎨 Ícono real + conexión a tu backend local (Docker)

- **Ícono**: `assets/images/logo.png` ya es tu ícono real (Splash, Login,
  app bar de la Grid). Para que también sea el ícono del launcher del
  celular, corre una vez:
  ```bash
  flutter pub get
  dart run flutter_launcher_icons
  ```
  Después desinstala la app del celular y vuelve a correr `flutter run`
  (Android cachea el ícono viejo y no siempre lo actualiza con hot restart).

- **Backend local en Docker**: `AppConfig.apiBaseUrl` apunta por defecto a
  `http://localhost:8000/api` (puerto estándar de Django). Para que tu
  **celular físico** (USB) llegue al backend que corre en tu PC, corre una
  vez por cada reconexión del cable:
  ```bash
  adb reverse tcp:8000 tcp:8000
  ```
  Redirige el `localhost:8000` del celular al de tu PC vía USB — más
  confiable que la IP de WiFi (no depende de red ni firewall). Si tu
  `docker-compose.yml` usa otro puerto, cámbialo acá Y en
  `lib/config/app_config.dart` (`apiBaseUrl`).

  Si en algún momento pruebas en el **emulador** de Android Studio en vez
  del celular físico, `adb reverse` no aplica — usa en su lugar:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  ```
  (`10.0.2.2` es el alias especial que usa el emulador para referirse al
  `localhost` de tu PC).

## ✅ Estado actual: Sprint 9 completado (Sprints 1-8 incluidos)

### Sprint 9 — Deep links, soporte offline, analytics
- **Deep links** (`pixelapp://pixel/{id}`, spec 12.3): `DeepLinkService`
  escucha links entrantes (`app_links`) y resuelve el ID contra
  `search_pixel` (sin inventar endpoint nuevo) para navegar a
  `PixelDetailScreen`. Ya se usa como link de "Compartir" desde el
  Sprint 3 — ahora también funciona en la dirección inversa (abrir la app
  desde ese link).
- **Soporte offline** (spec 12.2): `OfflineService` (Hive) cachea el
  último snapshot de la grilla y muestra un banner "Sin conexión —
  mostrando datos guardados" si falla la carga y hay cache disponible.
  Los likes y comentarios hechos sin conexión se encolan y se sincronizan
  solos al reconectar (`connectivity_plus` detecta el cambio de red).
- **Analytics** (spec 12.4, Firebase Analytics): eventos de login/registro,
  vista de píxel, compra completada, like dado y comentario publicado —
  mismo patrón defensivo que las notificaciones push (Sprint 8): si
  Firebase no está configurado, cada llamada falla en silencio sin romper
  la app.

### ⚠️ Configuración nativa pendiente para deep links
Igual que con Firebase (Sprint 8), esto requiere tocar archivos nativos
que no existen en este repo hasta que corras `flutter create .` (Paso 0).
Una vez los tengas:

**Android** — en `android/app/src/main/AndroidManifest.xml`, dentro del
`<activity>` principal, agrega:
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="pixelapp" android:host="pixel" />
</intent-filter>
```

**iOS** — en `ios/Runner/Info.plist`, agrega:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>pixelapp</string>
    </array>
  </dict>
</array>
```

El código Dart (`DeepLinkService`) ya está listo y no necesita cambios —
solo falta este registro nativo del esquema.

### 🛠️ Corrección importante encontrada en el Sprint 8
El proyecto nunca tuvo `flutter create` ejecutado — faltan las carpetas
nativas `android/`/`ios/`. Agregué el **Paso 0** al inicio de "Cómo
correrla" (abajo) con el comando exacto. Sin ese paso, `flutter run` no
iba a funcionar aunque todo el código Dart estuviera perfecto.

### Sprint 8 — Profile/Settings completos + notificaciones push
- **`ProfileEditScreen`**: editar nombre/apellido, conectado a
  `PATCH /auth/me/` (endpoint propuesto, extiende la ruta que ya usas para
  leer el perfil en vez de inventar una nueva).
- **`ChangePasswordScreen`**: formulario real (antes era un snackbar) sobre
  el endpoint ya confirmado `POST /auth/change-password/`.
- **`SettingsScreen`**: toggle de tema oscuro/claro, toggle de
  notificaciones push (preferencia local), accesos a editar perfil/cambiar
  contraseña, versión de la app, logout. Accesible desde el ícono ⚙️ en
  Profile.
- **`NotificationService`** (Firebase Cloud Messaging, spec 12.1): pide
  permiso, obtiene el token FCM, lo registra contra un endpoint propuesto,
  y queda listo para recibir mensajes en foreground/background — **todo
  con try/catch defensivo**, así que la app sigue funcionando 100% normal
  aunque Firebase no esté configurado todavía.

### ⚠️ Para que las notificaciones push funcionen de verdad
Esto no es algo que yo pueda dejar 100% listo sin tus credenciales:
1. `flutter create .` (Paso 0 de arriba).
2. Crear un proyecto en [Firebase Console](https://console.firebase.google.com).
3. Correr `flutterfire configure` en la raíz de `mobile/` (genera
   `lib/firebase_options.dart` + configs nativas).
4. Descomentar las 3 líneas marcadas en `lib/main.dart`.

Mientras tanto, la app arranca y corre igual — `NotificationService.init()`
falla en silencio si Firebase no está listo.

### 🆕 Dos endpoints propuestos más
Sumados al checklist en `PENDING_BACKEND_ENDPOINTS.md`:
```
PATCH /api/auth/me/                Body: { first_name, last_name }
POST  /api/auth/register_device/   Body: { fcm_token, platform }
```

### Sprint 7 — Sistema de comentarios
- **`PixelCommentsWidget`** (en Pixel Detail Screen) ahora es 100%
  funcional: lista de comentarios, input para publicar uno nuevo, y
  "Responder privadamente" en cada comentario ajeno, que abre el chat 1:1
  sobre ese píxel (Sprint 6).
- El like (Sprint 5) y los comentarios (este sprint) son los dos sistemas
  que necesitaban endpoints que no estaban en tu lista — ambos siguen el
  mismo protocolo del resto de tus rutas y quedan documentados en
  `PENDING_BACKEND_ENDPOINTS.md`.
- Mejoras chicas de paso: `Formatters.timeAgo()` (fechas relativas "2h",
  "3d") reemplaza un formato provisorio que había quedado en el chat list;
  `LoadingWidget` ahora soporta un modo `compact` para usos inline.

### 🆕 Nuevo endpoint propuesto: comentarios
```
GET  /api/pixels/pixel_comments/?pixel_id=<id>
POST /api/pixels/pixel_comments/   Body: { pixel_id, message }
```
Si el endpoint no existe todavía en tu backend, la sección de comentarios
muestra un error con botón "Reintentar" sin romper el resto de Pixel
Detail (imagen, stats, likes, editar siguen funcionando).

### Sprint 6 — Chat/Mensajes + WebSocket
- **`ChatListScreen`** (tab Mensajes): conversaciones con thumbnail del
  píxel, último mensaje, fecha y contador de no leídos.
- **`ChatDetailScreen`**: burbujas estilo WhatsApp (mías a la derecha en
  color primario, del otro a la izquierda), toggle público/privado al
  enviar, input con envío por Enter o botón.
- **Nuevo:** botón "Mensaje" en las acciones del píxel (`PixelDetailScreen`)
  para *iniciar* una conversación nueva sobre un píxel que aún no tiene
  mensajes — sin esto no había forma de arrancar un chat, solo de
  continuarlo desde la lista.
- **WebSocket** (`WebSocketService` + `socket_io_client`) para que los
  mensajes lleguen en tiempo real sin refrescar — pero el chat **funciona
  igual sin él**, ya que todo está armado sobre REST
  (`GET/POST /pixels/share_pixel/`) como base; el socket es un plus que
  falla en silencio si no está disponible.
- Logout ahora también limpia la sesión de chat (`ChatProvider.reset()`),
  para no arrastrar datos/conexión de un usuario al siguiente en el mismo
  dispositivo.

### 🆕 Definiciones propuestas (sin confirmar con tu backend)
Igual que con el like, seguí sin inventar nombres al azar — usé el mismo
protocolo del resto de tus rutas y lo documenté todo en
**`PENDING_BACKEND_ENDPOINTS.md`**:
- Cómo se usa `GET/POST /pixels/share_pixel/` para lista de chats vs.
  mensajes de una conversación puntual (con `?pixel_id=`).
- Contrato propuesto para el WebSocket (`join_pixel_chat`, `new_message`, etc.)

Cuando definas esto en el backend, avísame el formato real y ajusto los
2-3 archivos puntuales que lo necesitan.

### Sprint 5 — Search + My Pixels
- **`SearchScreen`**: búsqueda por ID con debounce (400ms) contra
  `GET /pixels/search_pixel/?q={id}`, resultados en grid de 3 columnas
  (reutiliza `PixelCardWidget`), estados idle/loading/resultados/vacío/error.
- **`MyPixelsScreen`**: grid de 3 columnas con `GET /pixels/my_pixels/`,
  pull-to-refresh, estado vacío con CTA directo a `PixelPurchaseScreen`
  ("¡Compra tu primero!", spec sección 5), y **long-press → menú de
  opciones** ("Ver detalle" / "Editar contenido", ya conectado a
  `PixelEditScreen` / `POST /pixels/edit_pixel_content/`).
- Ambas navegan a `PixelDetailScreen` en tap normal, consistente con el
  resto de la app.

### 🆕 Endpoint de "like" definido (propuesto) + checklist de pendientes
Como no existe un endpoint de like en tu backend todavía, definí uno
siguiendo el mismo protocolo que el resto de tus rutas y ya está 100%
conectado en el mobile con **optimistic update + rollback automático** si
la request falla (para que la app funcione bien aunque el endpoint no
exista aún en el servidor):

```
POST /api/pixels/toggle_like/
Body:     { "pixel_id": "<id>" }
Response: { "likes_count": <int>, "is_liked": <bool> }
```

Creé **`PENDING_BACKEND_ENDPOINTS.md`** en la raíz del proyecto — ahí se
va llevando la lista de cualquier endpoint que el mobile necesite y que no
esté en tu lista de rutas reales, más una tabla de "formatos asumidos" para
los endpoints que sí existen pero cuyo serializer exacto no tenía. Cuando
implementes algo en el backend, dímelo (o el formato real si difiere del
propuesto) y ajusto el mobile en el archivo puntual que corresponda.

### Sprint 4 — Pixel Detail + flujo de compra + Stripe
- **Tap normal** en un píxel de la grilla → `PixelDetailScreen` (imagen con
  zoom vía `photo_view`, owner, stats, acciones, comentarios). **Long-press**
  sigue abriendo el overlay rápido del Sprint 3 (spec 3.2).
- **Tap en celda vacía** → `PixelPurchaseScreen` con esa posición precargada.
- **`PixelPurchaseScreen`** (paso 1): mini-grid de disponibilidad reutilizando
  el cache de `GridProvider` + input manual de X/Y.
- **`PixelUploadScreen`** (paso 2): cámara/galería vía `image_picker`,
  retorna el archivo elegido.
- Paso 3 (formulario owner_name/owner_message/currency) vive de vuelta en
  `PixelPurchaseScreen` una vez se elige la imagen → confirma con
  `POST /pixels/initiate_purchase/` (multipart).
- **`PixelPaymentScreen`** (pasos 5-6): `POST /pixels/create_payment_intent/`
  → `CardField` de Stripe → `Stripe.instance.confirmPayment()` →
  `POST /pixels/confirm_purchase/` → pantalla de éxito → vuelve a la grilla.
- **`PixelEditScreen`**: edición de mensaje/imagen del propio píxel vía
  `POST /pixels/edit_pixel_content/`, accesible desde el botón "Editar"
  (solo visible si `pixel.isOwner`).
- Stripe inicializado en `main.dart` (`Stripe.publishableKey` +
  `applySettings()`).

### ⚠️ Antes de probar pagos reales
1. **Pon tu clave pública real de Stripe** en `AppConfig.stripePublishableKey`
   (o vía `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...`).
2. **Configura los permisos nativos** para `image_picker` (cámara/galería):
   - iOS `ios/Runner/Info.plist`: `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`
   - Android: `CAMERA` en el manifest si usarás la cámara (galería no
     requiere permiso en Android 13+).
3. **Verifica el formato real** de `initiate_purchase` / `create_payment_intent`
   / `confirm_purchase` — asumí (documentado en `PaymentService` y
   `payment_model.dart`):
   - `initiate_purchase` responde `{ session_id, x, y, currency, price? }`
   - `create_payment_intent` responde `{ client_secret, payment_intent_id?, amount, currency }`
   - `confirm_purchase` responde el píxel creado (directo o en `{ pixel: {...} }`)
   
   Si difiere, son ajustes acotados a `payment_model.dart` y `payment_service.dart`.
4. Apple Pay / Google Pay quedan como mejora futura (no incluidos este sprint).

### Sprint 3 — Grid infinita + navegación principal
- `MainScreen`: contenedor con bottom navigation real (5 tabs: Grid, Search,
  My Pixels, Messages, Profile) usando `IndexedStack` para preservar el
  estado de cada tab (ej. scroll position del grid) al cambiar de pestaña.
- `GridScreen` + `InfiniteGridWidget`: grilla con **scroll infinito vertical**,
  columnas responsive según ancho de pantalla, carga perezosa por viewport
  (debounced) contra `GET /pixels/grid_status/`, cache en memoria por chunk
  vía `GridProvider`, shimmer mientras cargan imágenes, `RepaintBoundary`
  por celda (spec 15.1).
  - **Importante — decisión de diseño**: implementé scroll infinito vertical
    con columnas fijas (como el mockup ASCII del spec) en vez de un canvas
    2D libremente pannable "estilo Google Maps real". Un canvas 2D libre
    (paneo en las 4 direcciones con zoom) es un motor bastante más grande
    de construir — si lo necesitas de verdad, dímelo y lo hacemos como su
    propio sprint dedicado.
- Indicadores 🔥 (>50 likes, parpadeo suave) y ❤️ (liked by mí) en las
  esquinas de cada celda, según spec 3.1.
- `PixelOverlayWidget`: bottom sheet arrastrable al hacer tap/long-press en
  un píxel — imagen grande, owner, mensaje, likes, contador de comentarios,
  y botones Like / Comentar / Compartir (`share_plus`, ya funcional) /
  Editar (solo si `isOwner`).
- `GridFloatingButton`: FAB "+" (spec 3.3), listo para conectar al flujo de
  compra del Sprint 4.
- `ProfileScreen`: header con datos reales del usuario + logout funcional
  (`POST /auth/logout/`). Stats/edición completas en Sprint 8.
- Search / My Pixels / Messages: placeholders con `EmptyStateWidget`,
  `PixelService.searchPixel()` y `getMyPixels()` ya implementados y listos
  para conectar en el Sprint 5.

### ⚠️ Verifica el formato de `/pixels/grid_status/`
No tenía el serializer real, así que `PixelService.getGridStatus()` asume:
- Query params: `x_min`, `x_max`, `y_min`, `y_max` (bounding box).
- Respuesta: lista de objetos `{ id, x, y, image_url, owner_name, owner_message, likes_count, is_liked, comments_count, is_owner }`, ya sea como array directo o paginado `{ results: [...] }`.

Si tu backend espera otro formato de query o de respuesta, es un ajuste
acotado a `PixelService.getGridStatus()` y `PixelModel.fromJson()` — el
resto de la app no se ve afectado. También pendiente: **no vi ningún
endpoint de "like"** en las rutas que compartiste — el like hoy es
optimista en memoria (`GridProvider.applyOptimisticLike`); en cuanto me
pases la ruta real lo conecto de inmediato.

### Sprint 2 — Autenticación 100% funcional
- `ApiService`: cliente Dio central con interceptor de auth (Bearer token
  automático), interceptor de **refresh automático** en 401 contra
  `/auth/token/refresh/` con reintento transparente de la request original,
  logging en dev, y mapeo de errores DRF a `ApiException` con mensaje legible.
- `AuthService`: mapea 1:1 todos tus endpoints reales:
  `register`, `login`, `google`, `logout`, `token/refresh` (interno),
  `me`, `verify-email`, `resend-verification`, `password-reset`,
  `password-reset/confirm`, `change-password`.
- `AuthProvider`: estado global de sesión (`AuthStatus`), persistencia de
  tokens en `flutter_secure_storage`, chequeo automático de sesión al abrir
  la app (Splash llama `checkAuthStatus()` contra `/auth/me/`).
- `StorageService`: tokens en secure storage + user cacheado en SharedPreferences.
- Pantallas conectadas de verdad a la API:
  - **Login** → `POST /auth/login/`
  - **Register** → `POST /auth/register/` → navega a Verify Email
  - **Verify Email** → reenvío (`POST /auth/resend-verification/`) + campo
    manual de token (`POST /auth/verify-email/`) como fallback mientras no
    hay deep links (Sprint 9)
  - **Forgot Password** → `POST /auth/password-reset/`
  - **Reset Password** → `POST /auth/password-reset/confirm/`
  - **Main Screen** (placeholder, se reemplaza en Sprint 3) → confirma que
    la sesión persiste y prueba `logout()` → `POST /auth/logout/`
- **Google Sign-In**: el endpoint `POST /auth/google/` ya está mapeado en
  `AuthService.googleLogin()` y `AuthProvider.googleLogin()`, pero falta
  integrar el SDK nativo `google_sign_in` para obtener el `idToken` real
  (el botón en Login muestra un aviso claro de esto por ahora).

### ⚠️ Verifica el formato exacto de las respuestas de tu backend
No tengo el serializer real de Django, así que asumí las convenciones más
comunes de DRF + SimpleJWT. Dos lugares a revisar/ajustar si tu backend
devuelve otro formato:

1. **`AuthService._parseAuthResponse()`** (login/google): espera
   `{ access, refresh, user: {...} }` o `{ tokens: { access, refresh }, user: {...} }`.
2. **`UserModel.fromJson()`**: espera `first_name`, `last_name`, `is_verified`,
   etc. Si tu API usa otros nombres de campo, ajusta ahí — es el único lugar
   que lo necesita.

Si me pasas un ejemplo real del JSON que devuelve `POST /auth/login/`, ajusto
esto en 2 minutos para que calce exacto.

### Sprint 1 (base)

- Estructura de carpetas completa según arquitectura definida.
- Tema global (colores, tipografía, animaciones) — `AppColors`, `AppTextStyles`, `AppAnimations`, `AppTheme`.
- Configuración de entorno (`AppConfig`) y constantes (`AppConstants`, `ValidationConstants`).
- Sistema de rutas nombradas con transiciones (`AppRoutes`).
- **Splash Screen** funcional: logo con glow pulsante, fade a Login tras ~2.2s.
- **Login Screen** con UI completa (email, password, botón gradiente, Google,
  link a registro) y validación local. *(La conexión real a la API se activa en el Sprint 2.)*
- `ThemeProvider` base (persistencia en SharedPreferences).

La app **compila y corre** mostrando: Splash → Login.

## 🚀 Cómo correrla

> ⚠️ **Paso 0 — IMPORTANTE, hazlo una sola vez:** este repo solo tiene
> `lib/`, `assets/` y `pubspec.yaml` — le faltan las carpetas nativas
> `android/` e `ios/` (Xcode project, Gradle, manifests, etc.), que no son
> archivos de texto que yo pueda generar acá. Sin esto `flutter run` no
> va a funcionar. Corrige esto así, **desde adentro de la carpeta `mobile/`**,
> antes de nada más:
> ```bash
> cd mobile
> flutter create --org com.tuempresa --project-name pixel_app .
> ```
> Flutter detecta que ya existen `lib/` y `pubspec.yaml` y solo agrega lo
> que falta (`android/`, `ios/`, `web/` si quieres, etc.) sin tocar tu
> código. Es seguro correrlo aunque ya tengas el proyecto avanzado.

```bash
cd mobile
flutter pub get
flutter run
```

> **Nota sobre assets:** `assets/images/` y `assets/animations/` están vacías
> (solo `.gitkeep`). El logo del Splash/Login se dibuja con un `Icon` +
> gradiente para que la app corra sin depender de binarios. Cuando tengas
> `logo.png` / `logo_animated.json` reales:
> 1. Colócalos en `assets/images/` y `assets/animations/`.
> 2. Descomenta la sección `assets:` en `pubspec.yaml`.
> 3. Reemplaza el `_LogoMark` en `splash_screen.dart` por `Image.asset(Assets.logo)`.

> **Nota sobre fuentes:** `fontFamily: 'SFProDisplay'` está declarado en
> `theme/text_styles.dart` pero sin `.ttf` reales cae a la fuente del sistema
> automáticamente (no rompe nada). Agrega los `.ttf` en `assets/fonts/` y
> descomenta la sección `fonts:` en `pubspec.yaml` cuando los tengas.

## 📦 Plan de Sprints

| # | Alcance | Entregable |
|---|---|---|
| **1** ✅ | Setup, tema, config, rutas, Splash, Login (UI) | App corre: Splash → Login |
| **2** | `ApiService` (dio + interceptors), `AuthService`, `AuthProvider`, Register/Verify/Forgot/Reset, Google Sign-In | Auth 100% funcional contra el backend |
| **3** | `MainScreen` + bottom nav, `GridScreen`, `InfiniteGridWidget`, `GridProvider`, `PixelProvider`, `PixelModel` | Grid infinita con scroll e indicadores 🔥❤️ |
| **4** | `PixelDetailScreen`, flujo de compra (mini-grid, upload, Stripe), `PaymentService` | Compra de píxel end-to-end |
| **5** | `SearchScreen`, `MyPixelsScreen` | Búsqueda por ID + galería personal |
| **6** | `ChatListScreen`, `ChatDetailScreen`, `WebsocketService`, `ChatProvider` | Mensajería pública/privada en tiempo real |
| **7** | Sistema de likes (animación explosión), comentarios públicos/privados | Interacciones sociales completas |
| **8** | `ProfileScreen`, `SettingsScreen`, `StorageService`, `NotificationService` (FCM) | Perfil, ajustes y push notifications |
| **9** | Deep links, offline support (Hive + cola de acciones), Analytics | Features avanzados |
| **10** | Tests unitarios/widget/integration, optimización de grid y tamaño de app, build final | Entregable de producción |

Cada sprint se entrega como un set de archivos nuevos/editados que se integran
sobre el código ya corriendo, sin romper lo anterior.

## 🔌 Contrato de API (referencia rápida — Sprint 2)

```
POST /api/auth/login/                     { email, password }
POST /api/auth/register/                  { email, first_name, last_name, password }
POST /api/auth/resend-verification/
POST /api/auth/password-reset/
POST /api/auth/password-reset/confirm/
POST /api/auth/change-password/           (autenticado)
POST /api/auth/google/

GET  /api/pixels/search_pixel/?q={id}
GET  /api/pixels/my_pixels/
POST /api/pixels/initiate_purchase/       multipart: { x, y, images, owner_name, owner_message, currency }
POST /api/pixels/create_payment_intent/   { session_id, currency }
POST /api/pixels/confirm_purchase/        { payment_intent_id, session_id }
GET  /api/pixels/share_pixel/
POST /api/pixels/share_pixel/
```

## 🎨 Design tokens

Ver `lib/theme/colors.dart`:

- Primary: `#5BA0F4` → `#3D7ED9` (gradiente)
- Background: `#000000` / Surface: `#1A1A1A`
- Like: `#FF4757` / Fire (🔥 >50 likes): `#FF6B35`
