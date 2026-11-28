import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_mobile/core/constants/app_colors.dart';
import 'package:campus_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:campus_mobile/shared/widgets/northstar_logo.dart';
import '../widgets/capsule_card.dart';
import '../widgets/edge_switcher_overlay.dart';
import 'module_screens.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key});

  void _navigateToModule(BuildContext context, int index) {
    Widget screen;
    switch (index) {
      case 0:
        screen = const DedicatedAcademicsScreen();
        break;
      case 1:
        screen = const DedicatedChannelsScreen();
        break;
      case 2:
      default:
        screen = const DedicatedFreelanceScreen();
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _openAiSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Campus AI Copilot',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Expanded(
              child: Center(
                child: Text(
                  'Connected to /api/ai/chat\nQuery timetable schedules, attendance alerts, and assignments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomIndex = ref.watch(bottomNavIndexProvider);
    final user = ref.watch(authControllerProvider).value;
    final isAdmin = user?.role == 'ADMIN';

    final List<Widget> bottomTabs = [
      _HomeHubView(
        onOpenModule: (idx) => _navigateToModule(context, idx),
        user: user,
      ),
      if (isAdmin) _AdminConsoleView(user: user),
      _ProfileView(user: user),
    ];

    return EdgeSwitcherOverlay(
      onSelectApp: (idx) => _navigateToModule(context, idx),
      onOpenAi: () => _openAiSheet(context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(
            children: [
              const NorthstarLogo(size: 38, mode: NorthstarLogoMode.idle),
              const SizedBox(width: 12),
              const Text(
                'Northstar Campus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'Campus AI Copilot',
              icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
              onPressed: () => _openAiSheet(context),
            ),
            const SizedBox(width: 14),
          ],
        ),
        body: IndexedStack(
          index: bottomIndex.clamp(0, bottomTabs.length - 1),
          children: bottomTabs,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: bottomIndex.clamp(0, bottomTabs.length - 1),
          onDestinationSelected: (idx) =>
              ref.read(bottomNavIndexProvider.notifier).state = idx,
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryContainer,
          elevation: 2,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Workspace',
            ),
            if (isAdmin)
              const NavigationDestination(
                icon: Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: Icon(Icons.admin_panel_settings, color: AppColors.primary),
                label: 'Admin',
              ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHubView extends StatelessWidget {
  final Function(int) onOpenModule;
  final dynamic user;

  const _HomeHubView({required this.onOpenModule, this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Text(
          'Hello, ${user?.fullName?.split(' ')?.first ?? 'Scholar'} 👋',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Select a domain capsule to enter your workspace',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        CapsuleCard(
          badgeText: '82.4% ATTENDANCE',
          title: 'Campus Academics',
          subtitle: 'Timetable · Statutory alerts · Courses',
          icon: Icons.school_rounded,
          iconColor: const Color(0xFF1D4ED8),
          iconBackgroundColor: const Color(0xFFDBEAFE),
          gradientColors: const [
            Color(0xFFEFF6FF),
            Color(0xFFE0E7FF),
          ],
          onTap: () => onOpenModule(0),
        ),

        CapsuleCard(
          badgeText: '3 ACTIVE SPACES',
          title: 'Channels & Spaces',
          subtitle: 'Real-time discussions · Voice rooms',
          icon: Icons.forum_rounded,
          iconColor: const Color(0xFF7C3AED),
          iconBackgroundColor: const Color(0xFFEDE9FE),
          gradientColors: const [
            Color(0xFFF3E8FF),
            Color(0xFFFFEDD5),
          ],
          onTap: () => onOpenModule(1),
        ),

        CapsuleCard(
          badgeText: 'CAMPUS MARKET',
          title: 'Freelance & Escrow',
          subtitle: 'Student gigs · Micro-contracts · Bounties',
          icon: Icons.work_rounded,
          iconColor: const Color(0xFF059669),
          iconBackgroundColor: const Color(0xFFD1FAE5),
          gradientColors: const [
            Color(0xFFECFDF5),
            Color(0xFFFEF3C7),
          ],
          onTap: () => onOpenModule(2),
        ),
      ],
    );
  }
}

class _AdminConsoleView extends StatelessWidget {
  final dynamic user;
  const _AdminConsoleView({this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        Text(
          'Institutional Administration',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(Icons.domain_verification, color: AppColors.primary),
            title: Text('Domain Verification'),
            subtitle: Text('Manage institutional email suffixes and whitelist rules'),
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends ConsumerWidget {
  final dynamic user;
  const _ProfileView({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryContainer,
              child: Icon(Icons.person, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              user.email,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text('${user.role} · ${user.accountType}'),
              backgroundColor: const Color(0xFFF1F5F9),
              side: const BorderSide(color: AppColors.border),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }
}