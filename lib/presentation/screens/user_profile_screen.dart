import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stockia/domain/entities/user_entity.dart';
import 'package:stockia/domain/entities/tenant_entity.dart';
import 'package:stockia/presentation/providers/auth_providers.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/screens/login_screen.dart';
import 'package:stockia/presentation/widgets/password_strength.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final bool asPage;
  const UserProfileScreen({super.key, this.asPage = true});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  int _selectedIndex = 0;

  static const _menuItems = [
    _MenuItem(icon: Icons.person, label: 'General'),
    _MenuItem(icon: Icons.lock, label: 'Seguridad'),
    _MenuItem(icon: Icons.card_membership, label: 'Suscripción'),
    _MenuItem(icon: Icons.logout, label: 'Cerrar Sesión'),
  ];

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserEntityProvider);

    return Scaffold(
      appBar: widget.asPage ? AppBar(title: const Text('Mi Cuenta')) : null,
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('No se encontró el usuario'));
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              if (isWide) {
                return Row(
                  children: [
                    SizedBox(width: 220, child: _buildMenu()),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildContent(user),
                      ),
                    ),
                  ],
                );
              }
              // Mobile: menu as horizontal chips + content below
              return Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: List.generate(_menuItems.length, (index) {
                        final item = _menuItems[index];
                        final selected = _selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: index == 3
                              ? ActionChip(
                                  avatar: Icon(
                                    item.icon,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  label: Text(
                                    item.label,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  onPressed: _handleLogout,
                                )
                              : ChoiceChip(
                                  avatar: Icon(item.icon, size: 18),
                                  label: Text(item.label),
                                  selected: selected,
                                  onSelected: (_) =>
                                      setState(() => _selectedIndex = index),
                                ),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: _buildContent(user),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenu() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: _menuItems.length,
        itemBuilder: (context, index) {
          final item = _menuItems[index];
          final selected = _selectedIndex == index;
          return ListTile(
            leading: Icon(
              item.icon,
              color: index == 3
                  ? Colors.red
                  : selected
                  ? Colors.deepPurple
                  : null,
            ),
            title: Text(
              item.label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: index == 3 ? Colors.red : null,
              ),
            ),
            selected: selected && index != 3,
            onTap: () {
              if (index == 3) {
                _handleLogout();
              } else {
                setState(() => _selectedIndex = index);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildContent(UserEntity user) {
    switch (_selectedIndex) {
      case 0:
        return _GeneralSection(user: user);
      case 1:
        return const _SecuritySection();
      case 2:
        return const _SubscriptionSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════
// General Section
// ═══════════════════════════════════════════════════════════

class _GeneralSection extends ConsumerStatefulWidget {
  final UserEntity user;
  const _GeneralSection({required this.user});

  @override
  ConsumerState<_GeneralSection> createState() => _GeneralSectionState();
}

class _GeneralSectionState extends ConsumerState<_GeneralSection> {
  final _companyNameController = TextEditingController();
  final _nitController = TextEditingController();
  final _legalRepController = TextEditingController();
  final _emailController = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  TenantEntity? _currentTenant;

  @override
  void dispose() {
    _companyNameController.dispose();
    _nitController.dispose();
    _legalRepController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _populateControllers(TenantEntity? tenant) {
    _currentTenant = tenant;
    _companyNameController.text = tenant?.name ?? '';
    _nitController.text = tenant?.nit ?? '';
    _legalRepController.text = tenant?.legalRepresentative ?? '';
    _emailController.text = widget.user.email;
  }

  @override
  Widget build(BuildContext context) {
    final tenantAsync = ref.watch(tenantEntityProvider);
    final authProvider = ref.watch(authProviderTypeProvider);
    final isSocialLogin =
        authProvider == 'google' || authProvider == 'microsoft';

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información General',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            tenantAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error al cargar empresa: $e'),
              data: (tenant) {
                if (!_editing && _currentTenant != tenant) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_editing) _populateControllers(tenant);
                  });
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField(
                      'Nombre de la Empresa',
                      _companyNameController,
                      tenant?.name ?? 'Sin nombre',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'NIT',
                      _nitController,
                      tenant?.nit ?? 'Sin NIT',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      'Correo electrónico',
                      _emailController,
                      widget.user.email,
                      enabled: !isSocialLogin,
                    ),
                    if (_editing && isSocialLogin) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'El correo no se puede editar porque iniciaste sesión con ${authProvider == 'google' ? 'Google' : 'Microsoft'}. '
                                'El cambio de correo debe realizarse desde tu cuenta de ${authProvider == 'google' ? 'Google' : 'Microsoft'}.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildField(
                      'Representante Legal',
                      _legalRepController,
                      tenant?.legalRepresentative ?? 'Sin información',
                    ),
                    const SizedBox(height: 16),
                    _infoRow('Id Interno Empresa', widget.user.tenantId),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_editing) ...[
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Guardar'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () {
                            setState(() {
                              _editing = false;
                              _populateControllers(_currentTenant);
                            });
                          },
                    child: const Text('Cancelar'),
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: () {
                      _populateControllers(_currentTenant);
                      setState(() => _editing = true);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String displayValue, {
    bool enabled = true,
  }) {
    if (!_editing) {
      return _infoRow(label, displayValue);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            isDense: true,
            filled: !enabled,
            fillColor: !enabled ? Colors.grey.shade200 : null,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Future<void> _save() async {
    final companyName = _companyNameController.text.trim();
    final nit = _nitController.text.trim();
    final legalRep = _legalRepController.text.trim();
    final newEmail = _emailController.text.trim();

    if (companyName.isEmpty) {
      _showError('El nombre de la empresa no puede estar vacío');
      return;
    }

    final authProvider = ref.read(authProviderTypeProvider);
    final isSocialLogin =
        authProvider == 'google' || authProvider == 'microsoft';
    final emailChanged = newEmail != widget.user.email && !isSocialLogin;

    // If email changed, check if already in use before asking for password
    if (emailChanged) {
      final inUse = await ref
          .read(authRepositoryProvider)
          .isEmailInUse(newEmail);
      if (inUse) {
        if (mounted) {
          _showError(
            'El correo $newEmail ya está registrado en otra cuenta. '
            'Por favor, usa un correo diferente.',
          );
        }
        return;
      }
    }

    // If email changed, ask for password
    String? password;
    if (emailChanged) {
      password = await _askForPassword();
      if (password == null) return; // User cancelled
    }

    setState(() => _saving = true);
    try {
      // Update tenant data
      await ref
          .read(updateTenantUseCaseProvider)
          .call(
            tenantId: widget.user.tenantId,
            name: companyName,
            nit: nit,
            legalRepresentative: legalRep,
          );

      // Update email if changed
      if (emailChanged && password != null) {
        await ref
            .read(updateEmailUseCaseProvider)
            .call(newEmail: newEmail, currentPassword: password);
      }

      ref.invalidate(tenantEntityProvider);
      ref.invalidate(currentUserEntityProvider);

      if (mounted) {
        setState(() {
          _editing = false;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              emailChanged
                  ? 'Datos actualizados. Se envió un correo de verificación a $newEmail.'
                  : 'Datos actualizados correctamente',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        String message = 'Error al actualizar: $e';
        final err = e.toString();
        if (err.contains('wrong-password') ||
            err.contains('invalid-credential')) {
          message = 'La contraseña ingresada es incorrecta';
        } else if (err.contains('invalid-email')) {
          message = 'El correo electrónico no es válido';
        } else if (err.contains('email-already-in-use')) {
          message = 'Ese correo electrónico ya está en uso por otra cuenta';
        }
        _showError(message);
      }
    }
  }

  Future<String?> _askForPassword() async {
    final passwordController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar identidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Para cambiar el correo electrónico, ingresa tu contraseña actual:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña actual',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final pwd = passwordController.text;
              if (pwd.isNotEmpty) Navigator.pop(ctx, pwd);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    passwordController.dispose();
    return result;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// ═══════════════════════════════════════════════════════════
// Security Section
// ═══════════════════════════════════════════════════════════

class _SecuritySection extends ConsumerStatefulWidget {
  const _SecuritySection();

  @override
  ConsumerState<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends ConsumerState<_SecuritySection> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _saving = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newPwd = _newPasswordController.text;
    final strength = PasswordValidator.strength(newPwd);

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cambiar Contraseña',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo requerido' : null,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: PasswordValidator.validate,
                ),
              ),
              // ── Barra de fortaleza ──
              if (newPwd.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: PasswordStrengthBar(strength: strength),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: PasswordRequirements(password: newPwd),
                ),
              ],
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
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
                    if (v == null || v.isEmpty) return 'Campo requerido';
                    if (v != _newPasswordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _changePassword,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_reset),
                label: const Text('Cambiar Contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(changePasswordUseCaseProvider)
          .call(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (mounted) {
        setState(() => _saving = false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contraseña actualizada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        String message = 'Error al cambiar la contraseña';
        final errorStr = e.toString();
        if (errorStr.contains('wrong-password') ||
            errorStr.contains('invalid-credential')) {
          message = 'La contraseña actual es incorrecta';
        } else if (errorStr.contains('weak-password')) {
          message = 'La nueva contraseña es muy débil';
        } else if (errorStr.contains('requires-recent-login')) {
          message =
              'Debes iniciar sesión nuevamente antes de cambiar la contraseña';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════
// Subscription Section (Pending)
// ═══════════════════════════════════════════════════════════

class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Suscripción',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            const Icon(Icons.construction, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Esta sección está en desarrollo.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Próximamente podrás gestionar tu plan de suscripción aquí.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Helper
// ═══════════════════════════════════════════════════════════

class _MenuItem {
  final IconData icon;
  final String label;
  const _MenuItem({required this.icon, required this.label});
}
