import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/domain/repositories/auth_repository.dart';
import 'package:stockia/presentation/providers/auth_providers.dart';
import 'package:stockia/presentation/screens/dashboard_screen.dart';

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
          backgroundColor: Colors.orange,
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
              backgroundColor: Colors.red,
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
                backgroundColor: Colors.green,
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

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Datos de la empresa',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Nombre empresa ──
                TextFormField(
                  controller: _companyNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la empresa *',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'NIT *',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                    hintText: 'Ej: 900.123.456-7',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa el NIT de la empresa'
                      : null,
                ),
                const SizedBox(height: 16),

                // ── Tipo de negocio ──
                DropdownButtonFormField<String>(
                  value: _selectedBusinessType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de negocio *',
                    prefixIcon: Icon(Icons.storefront),
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Nombre del representante legal *',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Ingresa el nombre del representante legal'
                      : null,
                ),
                const SizedBox(height: 32),

                Text(
                  'Credenciales de acceso',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Email ──
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico *',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Confirmar correo electrónico *',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
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
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa una contraseña';
                    }
                    if (v.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Confirmar contraseña ──
                TextFormField(
                  controller: _passwordConfirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña *',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
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
                const SizedBox(height: 20),

                // ── Términos y condiciones ──
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: 'Acepto los '),
                        TextSpan(
                          text: 'términos y condiciones',
                          style: const TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
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
                const SizedBox(height: 24),

                // ── Botón registrarse ──
                FilledButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: const Text('Crear cuenta'),
                ),
                const SizedBox(height: 12),

                // ── Volver al login ──
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
