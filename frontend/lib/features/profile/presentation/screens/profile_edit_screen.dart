import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/auth_widgets.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _nameCtrl = TextEditingController(text: auth.displayName ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  bool get _changingPassword => _newPassCtrl.text.isNotEmpty;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameCtrl.text.trim();
    final currentPass = _currentPassCtrl.text.isNotEmpty ? _currentPassCtrl.text : null;
    final newPass = _newPassCtrl.text.isNotEmpty ? _newPassCtrl.text : null;

    final auth = ref.read(authProvider);
    final nameUnchanged = name == (auth.displayName ?? '').trim();
    if (nameUnchanged && newPass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Değişiklik yapılmadı.')),
      );
      return;
    }

    setState(() => _loading = true);
    final error = await ref.read(authProvider.notifier).updateProfile(
      name: nameUnchanged ? null : name,
      currentPassword: currentPass,
      newPassword: newPass,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppTheme.primaryStatusRed,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil güncellendi.'),
          backgroundColor: AppTheme.primaryStatusGreen,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.softGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ── Geri ──────────────────────────────────────────────────
                IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(
                    Icons.arrow_back_ios_rounded,
                    color: isDark ? Colors.white70 : AppTheme.primaryBlue,
                  ),
                  padding: EdgeInsets.zero,
                ).animate().fadeIn(),

                const SizedBox(height: 20),

                Text(
                  'Profili Düzenle',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primaryBlue,
                  ),
                ).animate().fadeIn(delay: 60.ms).slideY(begin: -0.1),

                const SizedBox(height: 32),

                // ── İsim ──────────────────────────────────────────────────
                AuthFieldLabel('İsim', isDark),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: _nameCtrl,
                  hint: 'Adınız',
                  icon: Icons.person_outline_rounded,
                  isDark: isDark,
                  validator: (v) {
                    if (v == null || v.trim().length < 2) return 'En az 2 karakter';
                    return null;
                  },
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.06),

                const SizedBox(height: 28),

                // ── Şifre Değiştir ─────────────────────────────────────────
                Text(
                  'ŞİFRE DEĞİŞTİR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white38 : AppTheme.midGrey,
                    letterSpacing: 1.4,
                  ),
                ).animate().fadeIn(delay: 140.ms),

                const SizedBox(height: 12),

                AuthFieldLabel('Mevcut Şifre', isDark),
                const SizedBox(height: 8),
                _PasswordField(
                  controller: _currentPassCtrl,
                  hint: 'Mevcut şifreniz',
                  isDark: isDark,
                  obscure: _obscureCurrent,
                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (_changingPassword && (v == null || v.isEmpty)) {
                      return 'Mevcut şifre gerekli';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.06),

                const SizedBox(height: 14),

                AuthFieldLabel('Yeni Şifre', isDark),
                const SizedBox(height: 8),
                _PasswordField(
                  controller: _newPassCtrl,
                  hint: 'En az 6 karakter',
                  isDark: isDark,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && v.length < 6) {
                      return 'En az 6 karakter';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.06),

                const SizedBox(height: 14),

                AuthFieldLabel('Yeni Şifre (Tekrar)', isDark),
                const SizedBox(height: 8),
                _PasswordField(
                  controller: _confirmPassCtrl,
                  hint: 'Şifreyi tekrar girin',
                  isDark: isDark,
                  obscure: _obscureConfirm,
                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (_changingPassword && v != _newPassCtrl.text) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.06),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _loading ? null : _save,
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
                            'Kaydet',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.08),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.hint,
    required this.isDark,
    required this.obscure,
    required this.onToggle,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final bool obscure;
  final VoidCallback onToggle;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : AppTheme.textMuted,
        ),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: isDark ? Colors.white38 : AppTheme.midGrey,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: isDark ? Colors.white38 : AppTheme.midGrey,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppTheme.borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppTheme.borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryStatusRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppTheme.primaryStatusRed,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
