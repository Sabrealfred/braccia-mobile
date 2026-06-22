import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../widgets/app_widgets.dart';

/// Premium "Onyx & Gold" sign-in over the shared Supabase auth.
/// Email/password + Google OAuth + biometric unlock.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = LocalAuthentication();

  bool _loading = false;
  bool _googleLoading = false;
  bool _obscure = true;
  bool _biometricAvailable = false;
  String? _error;

  // Deep-link redirect for the Supabase OAuth callback.
  static const _oauthRedirect = 'io.bracciacapital.braccia://login-callback';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final supported =
          await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
      if (mounted) setState(() => _biometricAvailable = supported);
    } catch (_) {/* biometrics unavailable */}
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
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
    } catch (_) {
      setState(() => _error = 'Sign-in failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _oauthRedirect,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // Returns after launching the browser; the deep link completes sign-in.
    } catch (_) {
      setState(() => _error =
          'Google sign-in needs the Google provider enabled in Supabase.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _biometricUnlock() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock Braccia Capital',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!ok || !mounted) return;
      if (supabase.auth.currentSession != null) {
        // Session already persisted — router will move us along.
        setState(() {});
      } else {
        _snack('Sign in with email once to enable biometric unlock.');
      }
    } catch (_) {
      if (mounted) _snack('Biometric authentication unavailable.');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppText.sans(size: 13, color: Colors.white)),
        backgroundColor: AppColors.onyx700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.aiBackdrop),
        child: Stack(
          children: [
            // Decorative gold glow
            Positioned(
              top: -120,
              right: -80,
              child: _glow(220, AppColors.gold500.withValues(alpha: 0.18)),
            ),
            Positioned(
              bottom: -100,
              left: -90,
              child: _glow(200, AppColors.blueOnDark.withValues(alpha: 0.10)),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand mark
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.gold500.withValues(alpha: 0.45),
                                blurRadius: 30,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: Text('BC',
                              style: AppText.serif(
                                  size: 24, color: AppColors.goldInk)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Welcome back',
                          textAlign: TextAlign.center,
                          style:
                              AppText.serif(size: 30, color: AppColors.ivory)),
                      const SizedBox(height: 6),
                      Text(
                        'Braccia Capital — staff CRM',
                        textAlign: TextAlign.center,
                        style: AppText.sans(
                            size: 13.5,
                            color: AppColors.mutedOnDark,
                            weight: FontWeight.w300),
                      ),
                      const SizedBox(height: 30),

                      // Glass card
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius:
                              BorderRadius.circular(AppRadii.cardLarge),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => _snack(
                                    'Password reset link sent if the email exists.'),
                                style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 36),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4)),
                                child: Text('Forgot password?',
                                    style: AppText.sans(
                                        size: 12,
                                        color: AppColors.goldOnDark)),
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 16, color: AppColors.redOnDark),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(_error!,
                                        style: AppText.sans(
                                            size: 12.5,
                                            color: AppColors.redOnDark)),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 14),
                            GoldButton(
                              label: 'Sign in',
                              loading: _loading,
                              onTap: _signIn,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: _line()),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or continue with',
                                style: AppText.sans(
                                    size: 11.5, color: AppColors.muted)),
                          ),
                          Expanded(child: _line()),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Google + biometric row
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              label: 'Google',
                              loading: _googleLoading,
                              onTap: _signInWithGoogle,
                              leading: const _GoogleGlyph(),
                            ),
                          ),
                          if (_biometricAvailable) ...[
                            const SizedBox(width: 12),
                            _IconButtonTile(
                              icon: Icons.fingerprint,
                              onTap: _biometricUnlock,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),
                      Text(
                        'Grounded on the same data as crm.bracciacapital.com',
                        textAlign: TextAlign.center,
                        style: AppText.sans(
                            size: 11,
                            color: AppColors.muted,
                            weight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );

  Widget _line() => Container(
      height: 1, color: Colors.white.withValues(alpha: 0.10));
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget leading;
  final VoidCallback onTap;
  final bool loading;
  const _SocialButton({
    required this.label,
    required this.leading,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: loading ? () {} : onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ivory,
          borderRadius: BorderRadius.circular(14),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation(AppColors.ink)),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leading,
                  const SizedBox(width: 10),
                  Text(label,
                      style: AppText.sans(
                          size: 14.5,
                          color: AppColors.ink,
                          weight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class _IconButtonTile extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButtonTile({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: AppColors.gold300, size: 26),
      ),
    );
  }
}

/// Minimal multi-color Google "G" mark drawn without an asset.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final stroke = size.width * 0.22;
    final rect = Rect.fromCircle(center: c, radius: r - stroke / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    // Four arcs in Google's palette
    p.color = const Color(0xFF4285F4); // blue
    canvas.drawArc(rect, -0.5, 1.4, false, p);
    p.color = const Color(0xFF34A853); // green
    canvas.drawArc(rect, 0.95, 1.4, false, p);
    p.color = const Color(0xFFFBBC05); // yellow
    canvas.drawArc(rect, 2.4, 1.2, false, p);
    p.color = const Color(0xFFEA4335); // red
    canvas.drawArc(rect, 3.6, 1.5, false, p);
    // Crossbar
    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - stroke / 2, r, stroke),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
