# Splash nativo — cómo dejarlo idéntico al de Flutter

Este documento explica cómo terminar de configurar el splash nativo
(Android/iOS) para que sea **visualmente idéntico** al `SplashScreen` de
Flutter: fondo negro `#000000` + el mismo ícono, del mismo tamaño,
centrado. Así el usuario nunca percibe un "salto" entre el splash del
sistema y el de Flutter — se ve como una sola pantalla continua.

## Qué se cambió ya en el código

1. **`lib/screens/splash_screen.dart`**: se quitó toda la animación
   (glow pulsante, scale, `AnimationController`). Ahora es un `Scaffold`
   estático: fondo `AppColors.background` (negro) + un `Image.asset` del
   logo de `_kSplashLogoSize = 96` (dp), sin texto ni decoración.
2. **`pubspec.yaml`**: se agregó la sección `flutter_native_splash`
   (el paquete ya estaba en `dev_dependencies` desde antes), apuntando a
   `assets/images/logo.png` con `color: "#000000"` en todos los modos
   (claro/oscuro) y una sección `android_12` aparte (Android 12+ usa su
   propia API de splash con reglas de tamaño distintas).
3. **Android**: `drawable/launch_background.xml` y
   `drawable-v21/launch_background.xml` ahora usan
   `@android:color/black` en vez de blanco, y `styles.xml` /
   `values-night/styles.xml` cambiaron el `NormalTheme` a fondo negro
   explícito (evita un flash blanco justo antes de que Flutter dibuje su
   primer frame).

## Lo que TÚ tienes que hacer para completarlo

El repo todavía no tiene un `logo.png` real (`assets/images/` solo tiene
un `.gitkeep` de placeholder) — sin esa imagen, `flutter_native_splash`
no tiene qué generar. Pasos:

1. **Agrega el logo real** en `assets/images/logo.png`.
   - Formato PNG, fondo **transparente** (no blanco — si tiene fondo
     blanco vas a ver un cuadrado blanco sobre el negro).
   - Cuadrado, resolución alta (recomendado 1024×1024 px o similar) para
     que se vea nítido en cualquier densidad de pantalla.
   - **Recorte ajustado**: si el PNG tiene mucho margen/aire alrededor
     del ícono, se va a ver "más chico" que el mismo ícono en
     `SplashScreen` (que lo dibuja a 96×96 dp exactos, sin margen extra).
     Para que el tamaño percibido calce con el spec, el contenido visible
     dentro del PNG debería ocupar prácticamente todo el lienzo cuadrado.

2. **Instala dependencias y genera los assets nativos:**
   ```bash
   cd mobile
   flutter pub get
   dart run flutter_native_splash:create
   ```
   Esto genera automáticamente:
   - `android/app/src/main/res/drawable*/` con el ícono en las
     densidades correctas (reemplaza el placeholder comentado que
     dejamos en `launch_background.xml`).
   - Para Android 12+: los recursos bajo `values-v31/` (o similar) que
     usa la API nativa `SplashScreen` del sistema.
   - iOS: actualiza `ios/Runner/Assets.xcassets` y
     `LaunchScreen.storyboard` (solo si ya corriste `flutter create .`,
     ver README "Paso 0" — si `ios/` todavía no existe, corre ese paso
     primero).

3. **Verifica que el tamaño calce con Flutter.**
   El splash nativo (pre-Android 12) muestra el PNG a su tamaño físico
   real dividido por la densidad del dispositivo — no hay un "96dp"
   configurable directamente como en Flutter. Si después de generarlo el
   ícono nativo se ve visiblemente más grande o más chico que el de
   `SplashScreen` (96×96 dp), ajusta el **recorte/padding del PNG fuente**
   (paso 1) en vez de tratar de forzarlo por código — es la forma
   soportada por `flutter_native_splash` de controlar el tamaño
   percibido.
   - Para Android 12+, el sistema impone sus propias reglas: el ícono se
     recorta a un círculo de ~240dp con ~160dp de contenido visible en
     el centro — ligeramente distinto a versiones anteriores por
     restricción del OS, no por nuestra configuración.

4. **Reinstala la app** (no solo hot reload/restart): igual que con el
   ícono del launcher (ver README), Android/iOS cachean recursos de
   splash. Desinstala la app del dispositivo/emulador y vuelve a correr:
   ```bash
   flutter run
   ```

5. **(Opcional) Ajusta el tamaño en Flutter si decides otro valor.**
   Si terminas usando un tamaño distinto a 96dp para que calce mejor con
   el ícono nativo generado, cambia la constante `_kSplashLogoSize` en
   `lib/screens/splash_screen.dart` — es el único lugar que lo controla
   del lado de Flutter.

## Resultado esperado

- Splash nativo: fondo negro + ícono centrado, aparece apenas se toca el
  ícono de la app (antes de que exista cualquier Dart corriendo).
- Apenas Flutter dibuja su primer frame, `SplashScreen` (mismo fondo,
  mismo ícono, mismo tamaño) toma el control sin transición visible.
- Después de `_kMinimumDisplayTime` (600ms) + la validación de sesión
  (`checkAuthStatus()`), navega a Login o a Main — sin animaciones de por
  medio, tal como en Instagram/WhatsApp.
