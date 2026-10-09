import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';   
import 'package:app_links/app_links.dart';
import 'screens/rating_screen.dart'; 
import 'screens/home_screen.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart'; 
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'screens/login_screen.dart';
import 'screens/restablecer_contrasena_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  // Asegura que los bindings de Flutter estén listos antes de ejecutar código asíncrono
  WidgetsFlutterBinding.ensureInitialized();

  // Verificamos primero que NO estemos en la web (!kIsWeb) 
  // y luego verificamos que sea Android para forzar la tasa de refresco a 120Hz
  if (!kIsWeb && Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('No se pudo establecer 120Hz: $e');
    }
  }

  // 👈 2. Envolvemos la raíz de la app con ProviderScope
  runApp(
    const ProviderScope(
      child: RankSpotApp(),
    ),
  );
}

class RankSpotApp extends StatefulWidget {
  const RankSpotApp({super.key});

  @override
  State<RankSpotApp> createState() => _RankSpotAppState();
}

class _RankSpotAppState extends State<RankSpotApp> {
  final _appLinks = AppLinks();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // 1. Escuchar cuando la app ya está abierta o en segundo plano
    _appLinks.uriLinkStream.listen((uri) {
      _manejarEnlaceNFC(uri);
    });

    // 2. IMPORTANTE: Capturar el enlace si la app estaba CERRADA
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _manejarEnlaceNFC(initialUri);
      }
    } catch (e) {
      debugPrint("Error al obtener el enlace inicial: $e");
    }
  }

  void _manejarEnlaceNFC(Uri uri) {
    print("URI recibida en la app: $uri");

    // 1. Verificamos si el enlace es de restablecer contraseña
    final bool esResetPassword = uri.host == 'reset' ||
        uri.host == 'reset-password' ||
        uri.pathSegments.contains('reset') ||
        uri.pathSegments.contains('redirect-reset') ||
        uri.pathSegments.contains('reset-password');

    if (esResetPassword) {
      final String? token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        print("Token de recuperación detectado: $token");

        // Usamos addPostFrameCallback para asegurar que el Navigator esté montado si se abre en frío
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => RestablecerContrasenaScreen(token: token),
            ),
          );
        });
        return; // Salimos para no evaluar NFC
      }
    }

    // 2. Lógica existente para NFC / Calificaciones
    if (uri.pathSegments.contains('nfc')) {
      final codigoUnico = uri.pathSegments.last;
      print("NFC Detectado! Código: $codigoUnico");

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => RatingScreen(nfcCodigo: codigoUnico),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'RankSpot',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        brightness: Brightness.dark, // Le dice a Flutter que es un tema oscuro
        scaffoldBackgroundColor: const Color(0xFF0A1128), // Azul Marino Oscuro
        primaryColor: const Color(0xFF00E5FF), // Cian Eléctrico
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF), // Acentos
          surface: Color(0xFF1C2541), // Tarjetas y modales (Azul Pizarra)
          onSurface: Color(0xFFF4F5F7), // Textos principales (Blanco Hueso)
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFFF4F5F7)), // Iconos en blanco hueso
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF4F5F7)),
          bodyMedium: TextStyle(color: Color(0xFFF4F5F7)),
          titleLarge: TextStyle(color: Color(0xFFF4F5F7), fontWeight: FontWeight.bold),
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        // Aquí le indicamos explícitamente los tipos al mapa para que no haya confusiones
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const LoginScreen(),
    );
  }
}