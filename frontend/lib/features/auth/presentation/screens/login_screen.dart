import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(authProvider.notifier)
        .signIn(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.softGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // ── Geri ────────────────────────────────────────────────
                IconButton(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: isDark ? Colors.white70 : AppTheme.primaryBlue,
                  ),
                  padding: EdgeInsets.zero,
                ).animate().fadeIn(duration: 300.ms),

                const SizedBox(height: 24),

                // ── Logo ve Proje Adı ────────────────────────────────────
                Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                          tag: 'app_logo',
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 90,
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 24),

                // ── Başlık ───────────────────────────────────────────────
                Text(
                  'Hoş Geldin',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primaryBlue,
                  ),
                ).animate().fadeIn(delay: 60.ms).slideY(begin: -0.1),

                const SizedBox(height: 6),

                Text(
                  'Hesabına giriş yaparak kişiselleştirilmiş\ndeneyimin devam etsin.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : AppTheme.midGrey,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 40),

                // ── E-posta ──────────────────────────────────────────────
                AuthFieldLabel('E-posta', isDark),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _emailCtrl,
                  hint: 'ornek@mail.com',
                  icon: Icons.email_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'E-posta gerekli';
                    if (!v.contains('@')) return 'Geçerli e-posta girin';
                    return null;
                  },
                ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.06),

                const SizedBox(height: 20),

                // ── Şifre ────────────────────────────────────────────────
                AuthFieldLabel('Şifre', isDark),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _passCtrl,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  obscure: _obscure,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.midGrey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Şifre gerekli';
                    if (v.length < 6) return 'En az 6 karakter olmalı';
                    return null;
                  },
                ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.06),

                // ── Şifremi unuttum ──────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Şifremi unuttum',
                      style: TextStyle(
                        color: AppTheme.secondaryBlue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 210.ms),

                // ── Hata banner ──────────────────────────────────────────
                if (auth.errorMessage != null)
                  AuthErrorBanner(
                    auth.errorMessage!,
                  ).animate().fadeIn().shake(),

                const SizedBox(height: 8),

                // ── Giriş butonu ─────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: auth.isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Giriş Yap',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.08),

                const SizedBox(height: 24),

                // ── Kayıt yönlendirme ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hesabın yok mu? ',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppTheme.midGrey,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'Kayıt Ol',
                        style: TextStyle(
                          color: AppTheme.secondaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 280.ms),

                const SizedBox(height: 16),

                // ── Misafir devam ────────────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'Giriş yapmadan devam et',
                      style: TextStyle(
                        color: isDark ? Colors.white38 : AppTheme.midGrey,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
