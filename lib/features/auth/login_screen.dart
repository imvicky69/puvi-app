import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Minimal, warm, and intimate Login Screen for Puvi.
///
/// Features:
/// - Clean transparent logo badge with a warm medallion aesthetic.
/// - Romantic editorial typography (Cormorant Garamond + Caveat).
/// - Intuitive, tactile form inputs with validation and password reveal toggle.
/// - Standalone "Sign in with Google" entry ready for OAuth account syncing.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulated graceful sign-in entry
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Welcome home, ${_emailController.text.split('@').first} ✨',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.paper),
        ),
        backgroundColor: AppColors.espresso,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleGoogleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.dustyRose,
              size: 20,
            ),
            AppSpacing.horizontalSm,
            Expanded(
              child: Text(
                'Google Sign-In ready. Syncing with your account soon!',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.paper,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.espresso,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Header: Medallion Logo & Cute Romantic Salutation ---
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.espresso.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/logo_transparent.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    AppSpacing.verticalLg,

                    // Cute Handwritten Intimate Greeting
                    Center(
                      child: Text(
                        'our private corner',
                        style: AppTypography.handwrittenNote.copyWith(
                          fontSize: 22,
                          color: AppColors.burgundy,
                        ),
                      ),
                    ),

                    // App Editorial Title
                    Center(
                      child: Text(
                        'Puvi',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 38,
                          color: AppColors.espresso,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    AppSpacing.verticalXxs,

                    // Subtitle
                    Center(
                      child: Text(
                        'Step in to cherish our memories.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.taupe,
                        ),
                      ),
                    ),

                    AppSpacing.verticalXl,

                    // --- Form Card ---
                    Card(
                      elevation: 0,
                      color: AppColors.paper,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderCard,
                        side: BorderSide(color: AppColors.border, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Label & Field
                            Text(
                              'Email Address',
                              style: AppTypography.label.copyWith(
                                color: AppColors.espresso,
                                fontSize: 13,
                              ),
                            ),
                            AppSpacing.verticalXs,
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.espresso,
                              ),
                              decoration: InputDecoration(
                                hintText: 'puja@puvi.com or vicky@puvi.com',
                                hintStyle: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.taupe.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.mail_outline_rounded,
                                  color: AppColors.taupe,
                                  size: 20,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!val.contains('@') || !val.contains('.')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),

                            AppSpacing.verticalLg,

                            // Password Label & Field
                            Text(
                              'Secret Passcode',
                              style: AppTypography.label.copyWith(
                                color: AppColors.espresso,
                                fontSize: 13,
                              ),
                            ),
                            AppSpacing.verticalXs,
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.espresso,
                              ),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppColors.taupe,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppColors.taupe,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) {
                                  return 'Please enter your passcode';
                                }
                                if (val.length < 4) {
                                  return 'Passcode is at least 4 characters';
                                }
                                return null;
                              },
                            ),

                            AppSpacing.verticalSm,

                            // Remember Me & Forgot Passcode
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: _rememberMe,
                                            activeColor: AppColors.burgundy,
                                            checkColor: AppColors.paper,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            side: const BorderSide(
                                              color: AppColors.taupe,
                                              width: 1.5,
                                            ),
                                            onChanged: (val) {
                                              setState(() {
                                                _rememberMe = val ?? true;
                                              });
                                            },
                                          ),
                                        ),
                                        AppSpacing.horizontalXs,
                                        Flexible(
                                          child: Text(
                                            'Remember me',
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.caption
                                                .copyWith(
                                                  color: AppColors.espresso,
                                                  fontSize: 13,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Hint: Check your companion for the passcode 💕',
                                        ),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot passcode?',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.burgundy,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            AppSpacing.verticalLg,

                            // Primary Sign In Button
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.burgundy,
                                  foregroundColor: AppColors.paper,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.borderButton,
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.paper,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign In',
                                            style: AppTypography.label.copyWith(
                                              color: AppColors.paper,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          AppSpacing.horizontalXs,
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                            color: AppColors.paper,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            AppSpacing.verticalLg,

                            // Subtle Divider
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  child: Text(
                                    'or',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.taupe,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),

                            AppSpacing.verticalLg,

                            // Sign in with Google Button
                            SizedBox(
                              height: 50,
                              child: OutlinedButton(
                                onPressed: _handleGoogleSignIn,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.paper,
                                  foregroundColor: AppColors.espresso,
                                  side: const BorderSide(
                                    color: AppColors.border,
                                    width: 1.2,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.borderButton,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const _GoogleIcon(),
                                    AppSpacing.horizontalSm,
                                    Text(
                                      'Sign in with Google',
                                      style: AppTypography.label.copyWith(
                                        color: AppColors.espresso,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    AppSpacing.verticalLg,

                    // Cute Footer Note
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xs,
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: AppColors.dustyRose,
                          ),
                          Text(
                            'made for each other, always',
                            style: AppTypography.handwrittenCaption.copyWith(
                              fontSize: 15,
                              color: AppColors.taupe,
                            ),
                          ),
                          const Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: AppColors.dustyRose,
                          ),
                        ],
                      ),
                    ),

                    AppSpacing.verticalMd,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clean, crisp vector-drawn Google multi-color 'G' icon.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(20, 20), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius - paint.strokeWidth / 2,
    );

    // Blue arc (Right & top-right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.6, 1.2, false, paint);

    // Green arc (Bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.6, 1.3, false, paint);

    // Yellow arc (Bottom-left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 1.9, 1.3, false, paint);

    // Red arc (Top-left)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 3.2, 1.3, false, paint);

    // Blue crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = Rect.fromLTWH(
      center.dx - 1,
      center.dy - paint.strokeWidth / 2,
      radius - 1,
      paint.strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
