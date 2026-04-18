import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import 'auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent      = false;
  bool _loading   = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800)); // API stub
    if (mounted) setState(() { _loading = false; _sent = true; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.softGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Geri ──────────────────────────────────────────────────
              IconButton(
                onPressed: () => context.pop(),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: isDark ? Colors.white70 : AppTheme.primaryBlue,
                ),
                padding: EdgeInsets.zero,
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              // ── Başlık ─────────────────────────────────────────────────
              Text(
                'Şifreni Sıfırla',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryBlue,
                ),
              ).animate().fadeIn(delay: 60.ms).slideY(begin: -0.1),

              const SizedBox(height: 6),

              Text(
                _sent
                    ? 'E-posta gönderildi! Gelen kutunu kontrol et.'
                    : 'Kayıtlı e-posta adresine sıfırlama bağlantısı göndereceğiz.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white54 : AppTheme.midGrey,
                  height: 1.5,
                ),
              ).animate(key: ValueKey(_sent)).fadeIn(delay: 100.ms),

              const SizedBox(height: 40),

              if (_sent) ...[
                // ── Başarı durumu ────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryStatusGreen
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          color: AppTheme.primaryStatusGreen,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _emailCtrl.text,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'adresine e-posta gönderildi.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : AppTheme.midGrey,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: () => context.go('/login'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Giriş Ekranına Dön',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ] else ...[
                // ── Form ─────────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthFieldLabel('E-posta', isDark),
                      const SizedBox(height: 8),
                      AuthTextField(
                        controller:   _emailCtrl,
                        hint:         'ornek@mail.com',
                        icon:         Icons.email_outlined,
                        isDark:       isDark,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'E-posta gerekli';
                          }
                          if (!v.contains('@')) return 'Geçerli e-posta girin';
                          return null;
                        },
                      ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.06),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Sıfırlama Bağlantısı Gönder',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
