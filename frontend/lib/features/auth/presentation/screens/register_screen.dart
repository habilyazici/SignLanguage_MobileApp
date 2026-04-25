import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(authProvider.notifier)
        .register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
        );
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
                  onPressed: () => context.go('/login'),
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
                  'Hesap Oluştur',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primaryBlue,
                  ),
                ).animate().fadeIn(delay: 60.ms).slideY(begin: -0.1),

                const SizedBox(height: 6),

                Text(
                  'Ücretsiz hesap oluşturarak ilerlemeyi\ntakip et, buluta senkronize et.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : AppTheme.midGrey,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 36),

                // ── Ad Soyad ─────────────────────────────────────────────
                AuthFieldLabel('Ad Soyad', isDark),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _nameCtrl,
                  hint: 'Adın ve soyadın',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  keyboardType: TextInputType.name,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ad gerekli';
                    if (v.trim().length < 2) return 'En az 2 karakter girin';
                    return null;
                  },
                ).animate().fadeIn(delay: 130.ms).slideY(begin: 0.06),

                const SizedBox(height: 18),

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
                ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.06),

                const SizedBox(height: 18),

                // ── Şifre ────────────────────────────────────────────────
                AuthFieldLabel('Şifre', isDark),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _passCtrl,
                  hint: 'En az 6 karakter',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  obscure: _obscure1,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure1
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.midGrey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure1 = !_obscure1),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Şifre gerekli';
                    if (v.length < 6) return 'En az 6 karakter olmalı';
                    return null;
                  },
                ).animate().fadeIn(delay: 190.ms).slideY(begin: 0.06),

                const SizedBox(height: 18),

                // ── Şifre tekrar ─────────────────────────────────────────
                AuthFieldLabel('Şifre Tekrar', isDark),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _pass2Ctrl,
                  hint: 'Şifreni tekrar gir',
                  icon: Icons.lock_outline_rounded,
                  isDark: isDark,
                  obscure: _obscure2,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure2
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.midGrey,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscure2 = !_obscure2),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Şifreyi tekrar girin';
                    if (v != _passCtrl.text) return 'Şifreler eşleşmiyor';
                    return null;
                  },
                ).animate().fadeIn(delay: 210.ms).slideY(begin: 0.06),

                const SizedBox(height: 28),

                // ── Hata banner ──────────────────────────────────────────
                if (auth.errorMessage != null)
                  AuthErrorBanner(
                    auth.errorMessage!,
                  ).animate().fadeIn().shake(),

                // ── Kayıt butonu ─────────────────────────────────────────
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
                            'Kayıt Ol',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.08),

                const SizedBox(height: 24),

                // ── Giriş yönlendirme ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Zaten hesabın var mı? ',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppTheme.midGrey,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Giriş Yap',
                        style: TextStyle(
                          color: AppTheme.secondaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 270.ms),

                const SizedBox(height: 16),

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
                ).animate().fadeIn(delay: 290.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
