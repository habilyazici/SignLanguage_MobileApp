import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/screens/home_screen.dart';
import '../features/recognition/presentation/screens/recognition_screen.dart';
import 'scaffold_with_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title Sayfası Yolda...',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

final router = GoRouter(
  initialLocation: '/home',
  navigatorKey: _rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ScaffoldWithNav(child: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/live-translation',
          builder: (context, state) => const RecognitionScreen(),
        ),
        GoRoute(
          path: '/dictionary',
          builder: (context, state) => const PlaceholderScreen(title: 'Sözlük'),
        ),
        GoRoute(
          path: '/text-to-sign',
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Metinden İşarete'),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const PlaceholderScreen(title: 'Profil'),
        ),
      ],
    ),
  ],
);
