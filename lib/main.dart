import 'package:animatedmenu/sidemenu.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Color palette (3-5 colors total):
  // - Primary: teal
  // - Neutrals: near-white background, gray-900 foreground
  // - Accent: amber
  static const Color kPrimary = Color(0xFF1B2E6A); // teal-600
  static const Color kBackground = Color(0xFFF8FAFC); // slate-50
  static const Color kForeground = Color(0xFFFFFFFF); // slate-900
  static const Color kAccent = Color(0xFFF59E0B); // amber-500

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      surface: kBackground,
      background: kBackground,
      onPrimary: Colors.white,
      onSurface: kForeground,
      onBackground: kForeground,
      secondary: kAccent,
      onSecondary: Colors.white,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Liquid Side Menu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: kBackground,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(height: 1.5),
        ),
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidSideMenuScaffold(
      revealStyle: LiquidRevealStyle.bubble,
      menuHeader: const _MenuHeader(),
      menuItems: const [
        _MenuItem(icon: Icons.home_rounded, label: 'Home'),
        _MenuItem(icon: Icons.search_rounded, label: 'Search'),
        _MenuItem(icon: Icons.favorite_rounded, label: 'Favorites'),
        _MenuItem(icon: Icons.notifications_rounded, label: 'Notifications'),
        _MenuItem(icon: Icons.settings_rounded, label: 'Settings'),
      ],
      // Main content behind the liquid menu
      child: _HomeContent(
        onMenuTap: (ctx) => LiquidSideMenuController.of(ctx).toggle(),
      ),
      onSelect: (index) {
        // Handle menu item taps here
        debugPrint('Selected menu index: $index');
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.onMenuTap});
  final void Function(BuildContext) onMenuTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
              // padding: const EdgeInsets.all(20),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Open menu',
                        icon: const Icon(Icons.menu_rounded, color: Colors.white,),
                        onPressed: () => onMenuTap(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Liquid Side Menu',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 90,),
                  Text(
                    'Tap the menu icon to open. '
                        'The menu morphs with a smooth “liquid” curve following your drag.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  _CardTile(
                    title: 'Creative UI',
                    subtitle: 'Custom-painted cubic curves with interactive drag.',
                    icon: Icons.auto_awesome_rounded,
                  ),
                  _CardTile(
                    title: 'Smooth Animation',
                    subtitle: 'Spring-like transitions and item stagger animations.',
                    icon: Icons.animation_rounded,
                  ),
                  _CardTile(
                    title: 'Accessible',
                    subtitle: 'Semantics, focus, and tap targets considered.',
                    icon: Icons.accessibility_new_rounded,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      child:Image.asset('images/CXD-Logo-Blue-black.png', width: 40,),


    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: cs.onPrimary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: cs.onPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  const _MenuItemData({required this.icon, required this.label});
}