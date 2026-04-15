import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/presentation/widgets/glass_card.dart';
import '../../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Background handled by scaffold_with_nav
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 36,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.hearing),
            ),
            const SizedBox(width: 12),
            const Text('Hear Me Out'),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            // Hassasiyet eşiği
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -300) {
                // Sola doğru kaydırma -> Sağdaki menüye git (Metinden İşarete)
                context.go('/text-to-sign');
              } else if (details.primaryVelocity! > 300) {
                // Sağa doğru kaydırma -> Soldaki menüye git (Canlı Çeviri)
                context.go('/live-translation');
              }
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş Geldin !',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bugün ne öğrenmek\nistersin?',
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 40),
                // Daily Word GlassCard
                GlassCard(
                  borderRadius: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: AppTheme.primaryStatusYellow,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Günün İşareti',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '"Merhaba"',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontSize: 32,
                              color: AppTheme.primaryStatusGreen,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'İşaret dilinde temel selamlama.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Grid for tools (Focused Design)
                Row(
                  children: [
                    Expanded(
                      child: _buildActionGlassCard(
                        context: context,
                        title: 'İşareti Metne\nÇevir',
                        icon: Icons.back_hand_rounded,
                        color: AppTheme.secondaryBlue,
                        onTap: () => context.go('/live-translation'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionGlassCard(
                        context: context,
                        title: 'Metni İşarete\nÇevir',
                        icon: Icons.sign_language_rounded,
                        color: AppTheme.primaryBlue,
                        onTap: () => context.go('/text-to-sign'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                // Yönlendirme Bilgi Metni
                Center(
                  child: Text(
                    '💡 Hızlı Menü: Çeviri için sağa, Avatar için sola kaydırın',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black45,
                    ),
                  ),
                ),

                // Bottom padding to avoid overlap with floating bottom nav bar
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionGlassCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 36),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 18, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}
