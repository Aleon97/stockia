import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';
import 'package:stockia/presentation/providers/auth_providers.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/screens/register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(authNotifierProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text.trim());
  }

  Future<void> _socialLogin(SocialAuthProvider provider) async {
    await ref.read(authNotifierProvider.notifier).socialLogin(provider);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 LoginScreen.build() ejecutado');
    final authState = ref.watch(authNotifierProvider);

    ref.listen<AsyncValue>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_friendlyErrorMessage(error)),
              backgroundColor: Colors.red,
            ),
          );
        },
        data: (user) {
          if (user != null) {
            // Invalidar currentUserEntityProvider para que _AuthGate
            // detecte el nuevo usuario y navegue al Dashboard
            ref.invalidate(currentUserEntityProvider);
          }
        },
      );
    });

    final isLoading = authState.isLoading;
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  // ── Lado izquierdo: Logo ──
                  Expanded(
                    child: Container(
                      color: Colors.grey.shade100,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/logo_stockia.png',
                              width: 260,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Controla tu inventario',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // ── Lado derecho: Login ──
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(40),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _buildLoginForm(context, isLoading),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo_stockia.png',
                          width: 180,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Controla tu inventario',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 32),
                        _buildLoginForm(context, isLoading),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Inicia sesión en tu cuenta',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 32),

          // ── Email ──
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
              if (!v.contains('@')) return 'Email no válido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ── Contraseña ──
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // ── Botón login ──
          FilledButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Iniciar sesión'),
          ),
          const SizedBox(height: 24),

          // ── Separador ──
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('O continúa con'),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),

          // ── Social buttons ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialButton(
                label: 'Google',
                icon: Icons.g_mobiledata,
                color: Colors.red,
                onPressed: isLoading
                    ? null
                    : () => _socialLogin(SocialAuthProvider.google),
              ),
              const SizedBox(width: 12),
              _SocialButton(
                label: 'Microsoft',
                icon: Icons.window,
                color: Colors.blue,
                onPressed: isLoading
                    ? null
                    : () => _socialLogin(SocialAuthProvider.microsoft),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Link a registro ──
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: const Text('¿No tienes cuenta? Regístrate aquí'),
          ),
        ],
      ),
    );
  }

  String _friendlyErrorMessage(Object error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'El correo electrónico no es válido.';
        case 'user-disabled':
          return 'Esta cuenta ha sido deshabilitada.';
        case 'user-not-found':
          return 'No existe una cuenta con este correo electrónico.';
        case 'wrong-password':
          return 'La contraseña es incorrecta.';
        case 'invalid-credential':
          return 'Correo o contraseña incorrectos. Verifica tus datos.';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Intenta de nuevo más tarde.';
        case 'network-request-failed':
          return 'Error de conexión. Verifica tu internet.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con este correo electrónico.';
        case 'operation-not-allowed':
          return 'Este método de inicio de sesión no está habilitado.';
        case 'weak-password':
          return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
        case 'account-exists-with-different-credential':
          return 'Ya existe una cuenta con este correo usando otro método de inicio de sesión.';
        case 'popup-closed-by-user':
          return 'Se canceló el inicio de sesión.';
        default:
          return 'Error de autenticación. Intenta de nuevo.';
      }
    }
    final msg = error.toString();
    if (msg.contains('Usuario no encontrado')) {
      return 'Usuario no encontrado en la base de datos.';
    }
    return 'Ocurrió un error inesperado. Intenta de nuevo.';
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
