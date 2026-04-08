import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';
import 'package:stockia/presentation/providers/auth_providers.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/screens/register_screen.dart';
import 'package:stockia/presentation/theme/app_theme.dart';
import 'package:stockia/presentation/widgets/auth_branding_panel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

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
              backgroundColor: AppColors.danger,
            ),
          );
        },
        data: (user) {
          if (user != null) {
            ref.invalidate(currentUserEntityProvider);
          }
        },
      );
    });

    final isLoading = authState.isLoading;
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: isWide
          ? SafeArea(
              child: Row(
                children: [
                  // ── Lado izquierdo: Branding ──
                  const Expanded(child: AuthBrandingPanel()),
                  // ── Lado derecho: Login ──
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 32,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: _buildLoginForm(context, isLoading),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Branding header (mobile) ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0x26FFFFFF),
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xxl,
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/logo_stockia.png',
                                width: 120,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Gestiona tu inventario de forma inteligente',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ── Form section ──
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: _buildLoginForm(context, isLoading),
                      ),
                    ),
                  ],
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
          // ── Título ──
          Text(
            'Bienvenido de nuevo',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa tus credenciales para continuar',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // ── Email ──
          TextFormField(
            controller: _emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'tu@correo.com',
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu email';
              if (!v.contains('@')) return 'Email no válido';
              return null;
            },
          ),
          const SizedBox(height: 20),

          // ── Contraseña ──
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outlined, size: 20),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Ingresa tu contraseña';
              if (v.length < 6) return 'Mínimo 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 28),

          // ── Botón login ──
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Iniciar sesión',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Separador ──
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'O continúa con',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Social buttons ──
          Row(
            children: [
              _SocialButton(
                label: 'Google',
                icon: Icons.g_mobiledata,
                onPressed: isLoading
                    ? null
                    : () => _socialLogin(SocialAuthProvider.google),
              ),
              const SizedBox(width: 12),
              _SocialButton(
                label: 'Microsoft',
                icon: Icons.window,
                onPressed: isLoading
                    ? null
                    : () => _socialLogin(SocialAuthProvider.microsoft),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Link a registro ──
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('¿No tienes cuenta? Regístrate aquí'),
            ),
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
  final VoidCallback? onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 22),
          label: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
    );
  }
}
