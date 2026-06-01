import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../core/providers/camera_lifecycle_provider.dart';
import '../core/providers/translation_tab_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/welcome/presentation/screens/welcome_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/dictionary/presentation/screens/dictionary_screen.dart';
import '../features/dictionary/presentation/screens/dictionary_detail_screen.dart';
import '../features/translation/presentation/screens/translation_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/profile_edit_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import 'scaffold_with_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

// Giriş yapılmadan erişilebilen route'lar
const _guestAllowed = {
  '/welcome',
  '/login',
  '/register',
  '/forgot-password',
  '/onboarding',
  '/guest-camera',
};

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
}

// Misafir için tam ekran kamera — alt menü yok, geri → welcome
// ScaffoldWithNav/SwipeNavWrapper olmadığından tab geçişi burada yakalanır.
class _GuestCameraScreen extends ConsumerWidget {
  const _GuestCameraScreen();

  static const _velThreshold = 300.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) {
        // Geri tuşunda kamerayı durdur; yoksa keepAlive provider arka planda
        // kamerayı açık tutar (iOS'ta yeşil nokta, Android'de gereksiz kaynak kullanımı).
        ref.read(cameraActiveProvider.notifier).setActive(active: false);
        context.go('/welcome');
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity;
          if (v == null) return;
          if (v > _velThreshold) {
            ref.read(translationTabProvider.notifier).setTab(0);
          } else if (v < -_velThreshold) {
            ref.read(translationTabProvider.notifier).setTab(1);
          }
        },
        child: const TranslationScreen(initialTab: 0),
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/welcome',
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.matchedLocation;

      // Auth yüklenirken bekle
      if (auth.status == AuthStatus.loading) return null;

      final isLoggedIn = auth.isAuthenticated;

      // Giriş yapılmışsa auth ekranlarından çık
      if (isLoggedIn &&
          (path == '/welcome' ||
              path == '/login' ||
              path == '/register' ||
              path == '/guest-camera')) {
        return '/home';
      }

      // Giriş yapılmamışsa izin verilmeyen route'larda welcome'a yönlendir
      if (!isLoggedIn && !_guestAllowed.contains(path)) {
        return '/welcome';
      }

      return null;
    },
    routes: [
      // ── Auth gerektirmeyen route'lar ───────────────────────────────────
      GoRoute(
        path: '/welcome',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/guest-camera',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const _GuestCameraScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
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

      // ── Giriş gerektiren route'lar — ShellRoute (alt menülü) ──────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithNav(child: child),
        routes: [
          GoRoute(path: '/home',       builder: (context, _) => const HomeScreen()),
          GoRoute(path: '/dictionary', builder: (context, _) => const DictionaryScreen()),
          GoRoute(
            path: '/translation',
            builder: (context, state) {
              final tab = int.tryParse(
                    state.uri.queryParameters['tab'] ?? '',
                  ) ??
                  0;
              return TranslationScreen(initialTab: tab);
            },
          ),
          GoRoute(path: '/history', builder: (context, _) => const HistoryScreen()),
          GoRoute(path: '/profile', builder: (context, _) => const ProfileScreen()),
        ],
      ),

      // ── Giriş gerektiren route'lar — tam ekran (alt menüsüz) ──────────
      GoRoute(
        path: '/dictionary/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return DictionaryDetailScreen(wordId: id);
        },
      ),
      GoRoute(
        path: '/bookmarks',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
