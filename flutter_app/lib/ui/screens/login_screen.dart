import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../widgets/app_widgets.dart';

/// "Onyx & Gold" sign-in over the shared Supabase auth (same accounts as web).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await supabase.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      // router redirect handles navigation
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.aiBackdrop),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand mark
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: AppColors.goldGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Text('BC',
                            style: AppText.serif(
                                size: 13, color: AppColors.goldInk)),
                      ),
                      const SizedBox(width: 10),
                      Text('Braccia Capital',
                          style:
                              AppText.serif(size: 22, color: AppColors.ivory)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Staff CRM — sign in to continue',
                    textAlign: TextAlign.center,
                    style: AppText.sans(
                        size: 13,
                        color: AppColors.mutedOnDark,
                        weight: FontWeight.w300),
                  ),
                  const SizedBox(height: 34),

                  _DarkField(
                    controller: _email,
                    hint: 'Email',
                    icon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _DarkField(
                    controller: _password,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    onToggleObscure: () =>
                        setState(() => _obscure = !_obscure),
                    onSubmitted: (_) => _signIn(),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: AppColors.redOnDark),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(_error!,
                              style: AppText.sans(
                                  size: 12.5, color: AppColors.redOnDark)),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 22),
                  GoldButton(
                    label: 'Sign in',
                    loading: _loading,
                    onTap: _signIn,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Grounded on the same data as crm.bracciacapital.com',
                    textAlign: TextAlign.center,
                    style: AppText.sans(
                        size: 11, color: AppColors.muted, weight: FontWeight.w300),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onSubmitted;

  const _DarkField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.onToggleObscure,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.input),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.goldOnDark),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              keyboardType: keyboardType,
              onSubmitted: onSubmitted,
              style: AppText.sans(size: 14.5, color: AppColors.ivory),
              cursorColor: AppColors.gold300,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: InputBorder.none,
                hintText: hint,
                hintStyle:
                    AppText.sans(size: 14, color: const Color(0xFF86878D)),
              ),
            ),
          ),
          if (onToggleObscure != null)
            GestureDetector(
              onTap: onToggleObscure,
              child: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: const Color(0xFF86878D),
              ),
            ),
        ],
      ),
    );
  }
}
