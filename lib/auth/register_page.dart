import 'dart:convert';
import 'package:adde/auth/authentication_service.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/health_form_page.dart';
import 'package:flutter/material.dart';
import 'package:adde/component/input_fild.dart';
import 'package:adde/auth/login_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final AuthenticationService _authService = AuthenticationService();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _backgroundAnimationController;
  Animation<Color?>?
  _gradientColorAnimation; // Non-late to handle initialization safely
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _isLoading = false;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Ensure scroll position is reset
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;

    // Initialize gradient animation if not already set
    if (_gradientColorAnimation == null) {
      try {
        _gradientColorAnimation = ColorTween(
          begin: theme.colorScheme.primary.withOpacity(0.2),
          end: theme.colorScheme.secondary.withOpacity(0.2),
        ).animate(
          CurvedAnimation(
            parent: _backgroundAnimationController,
            curve: Curves.easeInOut,
          ),
        );
        _backgroundAnimationController.repeat(reverse: true);
      } catch (e) {
        // Log error and show dialog
        debugPrint('Animation initialization failed: $e');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorDialog('Failed to initialize registration page.');
        });
      }
    }

    // Update locale if changed
    if (_lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      setState(() {});
    }

    // Update fade animation based on loading state
    if (_isLoading) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _scrollController.dispose();
    _backgroundAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // Save Supabase session to SharedPreferences
  Future<void> _saveSession(Session session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = session.toJson();
      final sessionString = jsonEncode(sessionJson);
      await prefs.setString('supabase_session', sessionString);
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.signUpError(e.toString()));
      }
    }
  }

  // Handle Google Sign-In
  Future<void> _nativeGoogleSignIn() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    final webClientId = dotenv.env['WEB_CLIENT_ID'];

    if (webClientId == null || webClientId.isEmpty) {
      _showSnackBar(l10n.googleSignUpConfigError);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw l10n.googleSignUpCancelledError;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw l10n.googleSignUpTokenError;
      }

      final response = await Supabase.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          )
          .timeout(const Duration(seconds: 10));

      if (response.session != null && mounted) {
        await _saveSession(response.session!);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => MotherFormPage(
                  email: googleUser.email,
                  user_id: response.user!.id,
                ),
            settings: const RouteSettings(name: '/mother_form'),
          ),
        );
      } else {
        throw l10n.googleSignUpFailedError;
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().contains('cancelled')
              ? l10n.googleSignUpCancelledError
              : l10n.signUpError(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Handle email/password sign-up
  Future<void> _signUp(String email, String password) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    // Validate inputs
    if (email.isEmpty ||
        password.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showSnackBar(l10n.emptyFieldsError);
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar(l10n.invalidEmailError);
      return;
    }
    if (password.length < 6) {
      _showSnackBar(l10n.passwordTooShortError);
      return;
    }
    if (password != confirmPasswordController.text) {
      _showSnackBar(l10n.passwordsDoNotMatchError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService
          .signUpWithEmail(email, password)
          .timeout(const Duration(seconds: 10));

      if (response.session != null && response.user != null && mounted) {
        await _saveSession(response.session!);
        _showSnackBar(l10n.signUpSuccess, isSuccess: true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      MotherFormPage(email: email, user_id: response.user!.id),
              settings: const RouteSettings(name: '/mother_form'),
            ),
          );
        }
      } else {
        throw l10n.signUpFailedError;
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(l10n.signUpError(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Show error dialog for critical failures
  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              l10n.errorTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).brightness == Brightness.light
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(l10n.errorRetryButton),
              ),
            ],
          ),
    );
  }

  // Show animated SnackBar for feedback
  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  color:
                      isSuccess
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onError,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          isSuccess
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onError,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            )
            .animate()
            .slideY(
              begin: 0.5,
              end: 0,
              duration: 300.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeIn(duration: 300.ms, curve: Curves.easeIn),
        backgroundColor:
            isSuccess ? theme.colorScheme.primary : theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 4),
        action:
            isSuccess
                ? null
                : SnackBarAction(
                  label: l10n.retryButton,
                  textColor:
                      isSuccess
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onError,
                  onPressed: () {
                    if (message.contains('Google')) {
                      _nativeGoogleSignIn();
                    } else {
                      _signUp(emailController.text, passwordController.text);
                    }
                  },
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final l10n = AppLocalizations.of(context)!;

    // Fallback if animation initialization failed
    if (_gradientColorAnimation == null) {
      return _ErrorScreen(message: l10n.errorRegisterMessage);
    }

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            // Animated background gradient
            AnimatedBuilder(
              animation: _gradientColorAnimation!,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _gradientColorAnimation!.value ??
                            theme.colorScheme.primary.withOpacity(0.2),
                        theme.colorScheme.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              },
            ),
            // Main content
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.06,
                    bottom: screenHeight * 0.04,
                    left: 16,
                    right: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      children: [
                        _buildProfileImage(theme).animate().scale(
                          duration: 600.ms,
                          curve: Curves.easeOutBack,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        _buildWelcomeText(
                          theme,
                          l10n,
                        ).animate().fadeIn(duration: 500.ms),
                        SizedBox(height: screenHeight * 0.03),
                        _buildInputField(
                          emailController,
                          l10n.emailLabel,
                          false,
                          0,
                        ).animate().slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 500.ms,
                          delay: 100.ms,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildInputField(
                          passwordController,
                          l10n.passwordLabel,
                          true,
                          1,
                        ).animate().slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 500.ms,
                          delay: 200.ms,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildInputField(
                          confirmPasswordController,
                          l10n.confirmPasswordLabel,
                          true,
                          2,
                        ).animate().slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 500.ms,
                          delay: 300.ms,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        _buildSignUpButton(
                          theme,
                          l10n,
                        ).animate().scale(duration: 500.ms, delay: 400.ms),
                        SizedBox(height: screenHeight * 0.02),
                        _buildLoginLink().animate().fadeIn(
                          duration: 500.ms,
                          delay: 500.ms,
                        ),
                        SizedBox(height: screenHeight * 0.06),
                        _buildGoogleSignInButton().animate().scale(
                          duration: 500.ms,
                          delay: 600.ms,
                        ),
                        SizedBox(height: screenHeight * 0.04),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Loading overlay
            if (_isLoading)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: theme.colorScheme.shadow.withOpacity(0.3),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                      strokeWidth: 5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build profile image widget
  Widget _buildProfileImage(ThemeData theme) {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/user.png'),
          fit: BoxFit.cover,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }

  // Build welcome text widget
  Widget _buildWelcomeText(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.welcomeRegister,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.assistMessage,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Build input field widget
  Widget _buildInputField(
    TextEditingController controller,
    String hintText,
    bool obscure,
    int index,
  ) {
    return InputField(
      controller: controller,
      hintText: hintText,
      obscure: obscure,
      email: hintText == AppLocalizations.of(context)!.emailLabel,
    );
  }

  // Build sign-up button widget
  Widget _buildSignUpButton(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed:
            _isLoading
                ? null
                : () => _signUp(emailController.text, passwordController.text),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          elevation: 8,
          shadowColor: theme.colorScheme.primary.withOpacity(0.3),
        ).copyWith(
          elevation: WidgetStateProperty.resolveWith<double>(
            (states) => states.contains(WidgetState.pressed) ? 2 : 8,
          ),
        ),
        child:
            _isLoading
                ? CircularProgressIndicator(
                  color: theme.colorScheme.onPrimary,
                  strokeWidth: 2,
                )
                : Text(
                  l10n.signUpButton,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
      ),
    );
  }

  // Build login link widget
  Widget _buildLoginLink() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.alreadyHaveAccount,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(width: 5),
        GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                  settings: const RouteSettings(name: '/login'),
                ),
              ),
          child: Text(
            l10n.loginLink,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  // Build Google Sign-In button widget
  Widget _buildGoogleSignInButton() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: _isLoading ? null : _nativeGoogleSignIn,
      child: Container(
        width: 225,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
          color: theme.colorScheme.secondaryContainer,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/google.png', height: 24),
              const SizedBox(width: 8),
              Text(
                l10n.signUpWithGoogle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Error screen for unhandled widget errors
class _ErrorScreen extends StatelessWidget {
  final String message;

  const _ErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.errorTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(l10n.errorRetryButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
