import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/firebase_options.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/screens/login_screen.dart';
import 'package:stockia/presentation/theme/app_theme.dart';
import 'package:stockia/presentation/widgets/app_shell.dart';

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
      theme: buildAppTheme(),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerStatefulWidget {
  const _AuthGate();

  @override
  ConsumerState<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<_AuthGate> {
  Timer? _retryTimer;
  int _retryCount = 0;
  static const _maxRetries = 15;

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _scheduleEntityRetry() {
    if (_retryCount >= _maxRetries) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _retryCount++;
        debugPrint('🔄 Retry #$_retryCount para obtener user entity');
        ref.invalidate(currentUserEntityProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    debugPrint('🔑 AuthGate state: $authState');

    return authState.when(
      data: (firebaseUser) {
        debugPrint('🔑 AuthGate data: user=${firebaseUser?.email ?? "null"}');
        if (firebaseUser == null) {
          _retryCount = 0;
          _retryTimer?.cancel();
          return const LoginScreen();
        }

        // Firebase Auth tiene user, ahora esperar el entity de Firestore
        final userEntity = ref.watch(currentUserEntityProvider);
        return userEntity.when(
          data: (entity) {
            if (entity != null) {
              _retryCount = 0;
              _retryTimer?.cancel();
              return const AppShell();
            }
            // Doc Firestore aún no existe (race condition OAuth)
            _scheduleEntityRetry();
            return _buildLoadingScreen('Configurando tu cuenta...');
          },
          loading: () => _buildLoadingScreen('Cargando tu cuenta...'),
          error: (e, _) {
            _scheduleEntityRetry();
            return _buildLoadingScreen('Conectando...');
          },
        );
      },
      loading: () {
        debugPrint('🔑 AuthGate: loading...');
        return _buildLoadingScreen('Conectando con Firebase...');
      },
      error: (e, _) {
        debugPrint('🔑 AuthGate error: $e');
        return const LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}
