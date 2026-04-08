import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stockia/presentation/providers/auth_providers.dart';
import 'package:stockia/presentation/providers/core_providers.dart';
import 'package:stockia/presentation/providers/inventory_providers.dart';
import 'package:stockia/presentation/screens/dashboard_screen.dart';
import 'package:stockia/presentation/screens/inventory_movements_screen.dart';
import 'package:stockia/presentation/screens/login_screen.dart';

import 'package:stockia/presentation/screens/product_list_screen.dart';
import 'package:stockia/presentation/screens/reports_screen.dart';
import 'package:stockia/presentation/screens/stock_alerts_screen.dart';
import 'package:stockia/presentation/screens/user_profile_screen.dart';
import 'package:stockia/presentation/theme/app_theme.dart';

/// Index de cada sección del sidebar
enum NavSection { dashboard, products, movements, reports, alerts, settings }

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  NavSection _currentSection = NavSection.dashboard;
  bool _sidebarExpanded = true;

  static const _sidebarExpandedWidth = 260.0;
  static const _sidebarCollapsedWidth = 72.0;
  static const _mobileBreakpoint = 768.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isMobile ? _buildDrawer() : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(isMobile),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.sidebarBg,
      child: _buildSidebarContent(isDrawer: true),
    );
  }

  Widget _buildSidebar() {
    final w = _sidebarExpanded ? _sidebarExpandedWidth : _sidebarCollapsedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: w,
      color: AppColors.sidebarBg,
      child: _buildSidebarContent(),
    );
  }

  Widget _buildSidebarContent({bool isDrawer = false}) {
    final expanded = isDrawer || _sidebarExpanded;

    return SafeArea(
      child: Column(
        children: [
          // ── Logo ──
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo_stockia.png',
                  height: 32,
                  width: 32,
                  fit: BoxFit.contain,
                ),
                if (expanded) ...[
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'StockIA',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: AppColors.sidebarHover, height: 1),
          const SizedBox(height: AppSpacing.sm),

          // ── Navigation ──
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
            expanded: expanded,
            selected: _currentSection == NavSection.dashboard,
            onTap: () => _navigate(NavSection.dashboard, isDrawer),
          ),

          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            activeIcon: Icons.inventory_2,
            label: 'Productos',
            expanded: expanded,
            selected: _currentSection == NavSection.products,
            onTap: () => _navigate(NavSection.products, isDrawer),
          ),
          _SidebarItem(
            icon: Icons.swap_vert_outlined,
            activeIcon: Icons.swap_vert,
            label: 'Movimientos',
            expanded: expanded,
            selected: _currentSection == NavSection.movements,
            onTap: () => _navigate(NavSection.movements, isDrawer),
          ),
          _SidebarItem(
            icon: Icons.analytics_outlined,
            activeIcon: Icons.analytics,
            label: 'Reporte',
            expanded: expanded,
            selected: _currentSection == NavSection.reports,
            onTap: () => _navigate(NavSection.reports, isDrawer),
          ),
          _SidebarItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications,
            label: 'Alertas',
            expanded: expanded,
            selected: _currentSection == NavSection.alerts,
            onTap: () => _navigate(NavSection.alerts, isDrawer),
          ),

          const Spacer(),
          const Divider(color: AppColors.sidebarHover, height: 1),

          _SidebarItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Configuración',
            expanded: expanded,
            selected: _currentSection == NavSection.settings,
            onTap: () => _navigate(NavSection.settings, isDrawer),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Collapse toggle (solo desktop) ──
          if (!isDrawer)
            _SidebarItem(
              icon: _sidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
              label: _sidebarExpanded ? 'Colapsar' : '',
              expanded: expanded,
              selected: false,
              onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  void _navigate(NavSection section, bool isDrawer) {
    setState(() => _currentSection = section);
    if (isDrawer) Navigator.of(context).pop();
  }

  Widget _buildHeader(bool isMobile) {
    final userAsync = ref.watch(currentUserEntityProvider);
    final alertsAsync = ref.watch(stockAlertsStreamProvider);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          // Menu hamburger (mobile)
          if (isMobile)
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),

          // Título de la sección
          Text(
            _sectionTitle,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          const Spacer(),

          // Alertas badge
          alertsAsync.when(
            data: (alerts) => _HeaderIconButton(
              icon: Icons.notifications_outlined,
              badge: alerts.isNotEmpty ? '${alerts.length}' : null,
              onTap: () => setState(() => _currentSection = NavSection.alerts),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Avatar + user menu
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                offset: const Offset(0, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (user.displayName ?? user.email)
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (!_isMobile(context)) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        user.displayName ?? user.email,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.unfold_more,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ],
                ),
                onSelected: (value) async {
                  if (value == 'profile') {
                    setState(() => _currentSection = NavSection.settings);
                  } else if (value == 'logout') {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 18),
                        SizedBox(width: 8),
                        Text('Mi cuenta'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text(
                          'Cerrar sesión',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _mobileBreakpoint;

  String get _sectionTitle => switch (_currentSection) {
    NavSection.dashboard => 'Dashboard',
    NavSection.products => 'Productos',
    NavSection.movements => 'Movimientos',
    NavSection.reports => 'Reporte',
    NavSection.alerts => 'Alertas de Stock',
    NavSection.settings => 'Configuración',
  };

  Widget _buildContent() {
    return switch (_currentSection) {
      NavSection.dashboard => DashboardContent(
        onNavigate: (section) => setState(() => _currentSection = section),
      ),
      NavSection.products => const ProductListScreen(asPage: false),
      NavSection.movements => const InventoryMovementsScreen(asPage: false),
      NavSection.reports => const ReportsScreen(asPage: false),
      NavSection.alerts => const StockAlertsScreen(asPage: false),
      NavSection.settings => const UserProfileScreen(asPage: false),
    };
  }
}

// ── Sidebar components ──

class _SidebarSection extends StatelessWidget {
  final String label;
  final bool expanded;

  const _SidebarSection({required this.label, required this.expanded});

  @override
  Widget build(BuildContext context) {
    if (!expanded) return const SizedBox(height: AppSpacing.lg);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.sidebarText,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.expanded,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIcon = selected ? (activeIcon ?? icon) : icon;
    final color = selected
        ? AppColors.sidebarActiveText
        : AppColors.sidebarText;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: selected ? AppColors.sidebarActiveBg : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          hoverColor: AppColors.sidebarHover,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? AppSpacing.md : AppSpacing.sm,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(effectiveIcon, color: color, size: 20),
                if (expanded) ...[
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: badge != null
            ? Badge(
                label: Text(
                  badge!,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: AppColors.danger,
                child: Icon(icon, size: 22, color: AppColors.textSecondary),
              )
            : Icon(icon, size: 22, color: AppColors.textSecondary),
      ),
    );
  }
}
