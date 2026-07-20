// Smoke test básico: verifica que la app arranca y muestra el Splash Screen
// sin lanzar excepciones. Reemplaza el test_widget.dart genérico que
// `flutter create .` generó apuntando a una clase `MyApp` que no existe en
// este proyecto — nuestro widget raíz real es `PixelApp` (ver lib/app.dart).
//
// NOTA: como PixelApp usa providers (AuthProvider, GridProvider, etc.) que
// hacen llamadas async en su constructor/init (ej. AuthProvider no llama
// nada hasta checkAuthStatus(), así que esto es seguro), este test no
// necesita mockear la API para el smoke test más básico. Tests más
// completos con mocks de ApiService se agregan en el Sprint 10 (Testing).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:pixel_app/app.dart';
import 'package:pixel_app/providers/auth_provider.dart';
import 'package:pixel_app/providers/chat_provider.dart';
import 'package:pixel_app/providers/grid_provider.dart';
import 'package:pixel_app/providers/pixel_provider.dart';
import 'package:pixel_app/providers/theme_provider.dart';

void main() {
  testWidgets('App arranca y muestra el Splash Screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => GridProvider()),
          ChangeNotifierProvider(create: (_) => PixelProvider()),
          ChangeNotifierProvider(create: (_) => ChatProvider()),
        ],
        child: const PixelApp(),
      ),
    );

    // No usamos pumpAndSettle() a propósito: el Splash tiene una animación
    // en loop infinito (repeat(reverse: true)) que nunca "se asienta".
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
