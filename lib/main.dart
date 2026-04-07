import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/firebase_options.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/screens/dashboard_screen.dart';
import 'package:stockia/presentation/screens/login_screen.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        debugPrint('❌ FlutterError: ${details.exception}');
        debugPrint('Stack: ${details.stack}');
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${details.exception}',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      };

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase inicializado correctamente');
      } catch (e) {
        debugPrint('❌ Error al inicializar Firebase: $e');
      }

      runApp(const ProviderScope(child: StockIAApp()));
    },
    (error, stack) {
      debugPrint('❌ Unhandled error: $error');
      debugPrint('Stack: $stack');
    },
  );
}

class StockIAApp extends ConsumerWidget {
  const StockIAApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'StockIA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    debugPrint('🔑 AuthGate state: $authState');

    return authState.when(
      data: (user) {
        debugPrint('🔑 AuthGate data: user=${user?.email ?? "null"}');
        if (user == null) return const LoginScreen();
        return const DashboardScreen();
      },
      loading: () {
        debugPrint('🔑 AuthGate: loading...');
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Conectando con Firebase...'),
              ],
            ),
          ),
        );
      },
      error: (e, _) {
        debugPrint('🔑 AuthGate error: $e');
        // Si hay error de Firebase, mostrar LoginScreen directamente
        return const LoginScreen();
      },
    );
  }
}
