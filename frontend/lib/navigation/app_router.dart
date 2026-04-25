import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/dictionary/presentation/screens/dictionary_screen.dart';
import '../features/dictionary/presentation/screens/dictionary_detail_screen.dart';
import '../features/translation/presentation/screens/translation_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import 'scaffold_with_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final router = GoRouter(
  initialLocation: '/splash',
  navigatorKey: _rootNavigatorKey,
  routes: [
    // ── Giriş akışı (bottom nav yok) ─────────────────────────────────
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),

    // ── Shell: bottom nav taşıyan 5 tab ──────────────────────────────
    // 0=Anasayfa  1=Sözlük  2=Çeviri  3=Geçmiş  4=Profil
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => ScaffoldWithNav(child: child),
      routes: [
        GoRoute(path: '/home',        builder: (context, _) => const HomeScreen()),
        GoRoute(path: '/dictionary',  builder: (context, _) => const DictionaryScreen()),
        GoRoute(path: '/translation', builder: (context, _) => const TranslationScreen()),
        GoRoute(path: '/gecmis',      builder: (context, _) => const HistoryScreen()),
        GoRoute(path: '/profile',     builder: (context, _) => const ProfileScreen()),
      ],
    ),

    // ── Tam ekran rotalar (bottom nav yok) ───────────────────────────
    GoRoute(
      path: '/dictionary/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return DictionaryDetailScreen(wordId: id);
      },
    ),

    // ── Ayarlar (bottom nav yok, profil'den açılır) ──────────────────
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),

    // ── Auth rotaları (bottom nav yok) ───────────────────────────────
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
  ],
);
