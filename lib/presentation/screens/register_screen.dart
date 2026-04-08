import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';
import 'package:stockia/presentation/providers/auth_providers.dart';
import 'package:stockia/presentation/screens/dashboard_screen.dart';
import 'package:stockia/presentation/theme/app_theme.dart';
import 'package:stockia/presentation/widgets/auth_branding_panel.dart';
import 'package:stockia/presentation/widgets/password_strength.dart';

const List<String> _businessTypes = [
  'Ferretería',
  'Supermercado',
  'Repuestos de carro',
  'Repuestos de moto',
  'Cámaras y tecnología',
  'Ropa y accesorios',
  'Farmacia',
  'Papelería',
  'Restaurante',
  'Construcción',
  'Electrónica',
  'Otro',
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _nitController = TextEditingController();
  final _legalRepController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailConfirmController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  String? _selectedBusinessType;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _nitController.dispose();
    _legalRepController.dispose();
    _emailController.dispose();
    _emailConfirmController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Términos y Condiciones'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TÉRMINOS Y CONDICIONES DE USO DE STOCKIA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Última actualización: 7 de abril de 2026',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              SizedBox(height: 16),
              Text(
                '1. ACEPTACIÓN DE LOS TÉRMINOS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Al registrarte y utilizar StockIA, aceptas estos términos y condiciones '
                'en su totalidad. Si no estás de acuerdo, no debes utilizar el servicio.',
              ),
              SizedBox(height: 16),
              Text(
                '2. DESCRIPCIÓN DEL SERVICIO',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'StockIA es una plataforma de gestión de inventarios que permite a empresas '
                'administrar productos, movimientos de stock y alertas de inventario bajo.',
              ),
              SizedBox(height: 16),
              Text(
                '3. REGISTRO Y CUENTA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Debes proporcionar información veraz y actualizada.\n'
                '• Eres responsable de mantener la confidencialidad de tu contraseña.\n'
                '• Cada empresa debe tener un NIT válido para registrarse.\n'
                '• No debes compartir tu cuenta con terceros no autorizados.',
              ),
              SizedBox(height: 16),
              Text(
                '4. PRIVACIDAD Y PROTECCIÓN DE DATOS',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Los datos de tu empresa se almacenan de forma segura y aislada (multi-tenant).\n'
                '• No compartimos tu información con terceros sin tu consentimiento.\n'
                '• Cumplimos con las normativas vigentes de protección de datos personales.\n'
                '• Puedes solicitar la eliminación de tus datos en cualquier momento.',
              ),
              SizedBox(height: 16),
              Text(
                '5. USO ACEPTABLE',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• No debes usar el servicio para actividades ilegales.\n'
                '• No debes intentar acceder a datos de otros tenants.\n'
                '• No debes realizar ingeniería inversa del software.',
              ),
              SizedBox(height: 16),
              Text(
                '6. LIMITACIÓN DE RESPONSABILIDAD',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'StockIA se proporciona "tal cual". No garantizamos la disponibilidad '
                'ininterrumpida del servicio. No somos responsables por pérdidas derivadas '
                'de interrupciones del servicio o pérdida de datos.',
              ),
              SizedBox(height: 16),
              Text(
                '7. MODIFICACIONES',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Nos reservamos el derecho de modificar estos términos en cualquier momento. '
                'Te notificaremos sobre cambios significativos por correo electrónico.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _acceptedTerms = true);
              Navigator.of(ctx).pop();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final data = SignUpData(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      companyName: _companyNameController.text.trim(),
      nit: _nitController.text.trim(),
      businessType: _selectedBusinessType ?? '',
      legalRepresentative: _legalRepController.text.trim(),
    );

    await ref.read(authNotifierProvider.notifier).register(data);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen<AsyncValue>(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.danger,
            ),
          );
        },
        data: (user) {
          if (user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Cuenta creada. Se envió un correo de verificación.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (_) => false,
            );
          }
        },
      );
    });

    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: isWide ? AppColors.surface : AppColors.background,
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  // ── Lado izquierdo: Branding ──
                  const Expanded(child: AuthBrandingPanel()),
                  // ── Lado derecho: Formulario ──
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: _buildRegisterForm(context, isLoading),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        // ── Mobile header ──
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Image.asset(
                          'assets/images/logo_stockia.png',
                          width: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),
                        _buildRegisterForm(context, isLoading),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Text(
            'Crear cuenta',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completa la información para registrar tu empresa',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),

          // ══════════════════════════════════════
          // SECCIÓN 1: Datos de la empresa
          // ══════════════════════════════════════
          _SectionCard(
            icon: Icons.business_outlined,
            title: 'Datos de la empresa',
            children: [
              // ── Nombre empresa ──
              TextFormField(
                controller: _companyNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nombre de la empresa *',
                  hintText: 'Ej: Mi Empresa S.A.S',
                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Ingresa el nombre de la empresa'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── NIT ──
              TextFormField(
                controller: _nitController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'NIT *',
                  hintText: 'Ej: 900.123.456-7',
                  prefixIcon: const Icon(Icons.numbers_outlined, size: 20),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Ingresa el NIT de la empresa'
                    : null,
              ),
              const SizedBox(height: 16),

              // ── Tipo de negocio ──
              DropdownButtonFormField<String>(
                initialValue: _selectedBusinessType,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Tipo de negocio *',
                  prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                items: _businessTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedBusinessType = v),
                validator: (v) =>
                    v == null ? 'Selecciona el tipo de negocio' : null,
              ),
              const SizedBox(height: 16),

              // ── Representante legal ──
              TextFormField(
                controller: _legalRepController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nombre del representante legal *',
                  hintText: 'Nombre completo',
                  prefixIcon: const Icon(Icons.person_outlined, size: 20),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Ingresa el nombre del representante legal'
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ══════════════════════════════════════
          // SECCIÓN 2: Credenciales de acceso
          // ══════════════════════════════════════
          _SectionCard(
            icon: Icons.lock_outlined,
            title: 'Credenciales de acceso',
            children: [
              // ── Email ──
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico *',
                  hintText: 'tu@correo.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Ingresa tu correo electrónico';
                  }
                  final emailRegex = RegExp(
                    r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$',
                  );
                  if (!emailRegex.hasMatch(v.trim())) {
                    return 'Correo electrónico no válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Confirmar email ──
              TextFormField(
                controller: _emailConfirmController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Confirmar correo electrónico *',
                  hintText: 'Repite tu correo',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Confirma tu correo electrónico';
                  }
                  if (v.trim() != _emailController.text.trim()) {
                    return 'Los correos no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Contraseña ──
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
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
                validator: PasswordValidator.validate,
              ),
              // ── Barra de fortaleza y requisitos ──
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                PasswordStrengthBar(
                  strength: PasswordValidator.strength(
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: 8),
                PasswordRequirements(password: _passwordController.text),
              ],
              const SizedBox(height: 16),

              // ── Confirmar contraseña ──
              TextFormField(
                controller: _passwordConfirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña *',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Confirma tu contraseña';
                  }
                  if (v != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Términos y condiciones ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Acepto los '),
                        TextSpan(
                          text: 'términos y condiciones',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _showTermsDialog(context),
                        ),
                        const TextSpan(text: ' *'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Botón registrarse ──
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
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Crear cuenta',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Volver al login ──
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('¿Ya tienes cuenta? Inicia sesión'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Card visual para agrupar secciones del formulario de registro.
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ...children,
        ],
      ),
    );
  }
}
