import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// İleride sayfaları geliştirdikçe bu placeholder widget'ları sileceğiz
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Sayfası',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

final router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) =>
          const PlaceholderScreen(title: 'Ana Sayfa (Hub)'),
    ),
    // İleride buraya Bottom Navigation için ShellRoute veya StatefulShellRoute ekleyeceğiz
    GoRoute(
      path: '/dictionary',
      builder: (context, state) => const PlaceholderScreen(title: 'Sözlük'),
    ),
    GoRoute(
      path: '/live-translation',
      builder: (context, state) =>
          const PlaceholderScreen(title: 'Canlı Çeviri'),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const PlaceholderScreen(title: 'Ayarlar'),
    ),
  ],
);
