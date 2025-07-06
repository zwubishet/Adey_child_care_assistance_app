import 'dart:convert';
import 'package:adde/auth/change_password_page.dart';
import 'package:adde/auth/register_page.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:adde/pages/bottom_page_navigation.dart';
import 'package:adde/auth/authentication_service.dart';
import 'package:adde/component/input_fild.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthenticationService authenticationService = AuthenticationService();
  final supabase = Supabase.instance.client;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _backgroundAnimationController;
  late Animation<Color?> _gradientColorAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
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

    if (_lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      setState(() {});
    }

    if (!_backgroundAnimationController.isAnimating) {
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
    }

    if (_isLoading) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  Future<void> _saveSession(Session session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = session.toJson();
      final sessionString = jsonEncode(sessionJson);
      await prefs.setString('supabase_session', sessionString);
    } catch (e) {
      if (mounted) {
        _showSnackBar(AppLocalizations.of(context)!.errorLabel(e.toString()));
      }
    }
  }

  Future<void> _nativeGoogleSignIn() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final l10n = AppLocalizations.of(context)!;
    final webClientId = dotenv.env['WEB_CLIENT_ID'];

    if (webClientId == null || webClientId.isEmpty) {
      _showSnackBar(l10n.googleSignInConfigError);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw l10n.googleSignInCancelledError;
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw l10n.googleAuthFailedError;
      }

      final response = await supabase.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: googleAuth.idToken!,
            accessToken: googleAuth.accessToken!,
          )
          .timeout(const Duration(seconds: 10));

      if (response.session != null && mounted) {
        await _saveSession(response.session!);
        _showSnackBar(l10n.signInSuccess, isSuccess: true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BottomPageNavigation(
                    user_id: response.user!.id,
                    email: response.user?.email ?? googleUser.email,
                  ),
              settings: const RouteSettings(name: '/bottom_navigation'),
            ),
          );
        }
      } else {
        throw l10n.googleSignInFailedError;
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          e.toString().contains('cancelled')
              ? l10n.googleSignInCancelledError
              : l10n.errorLabel(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _login() async {
    if (!mounted) return;

    final email = userNameController.text.trim();
    final password = passwordController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(l10n.emptyFieldsError);
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar(l10n.invalidEmailError);
      return;
    }
    if (password.length < 6) {
      _showSnackBar(l10n.invalidPasswordError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await authenticationService
          .signInWithEmailAndPassword(email, password)
          .timeout(const Duration(seconds: 10));

      if (response.session != null && mounted) {
        await _saveSession(response.session!);
        final user = response.user;
        if (user == null) {
          throw l10n.loginFailedError;
        }
        _showSnackBar(l10n.signInSuccess, isSuccess: true);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => BottomPageNavigation(
                    user_id: user.id,
                    email: user.email ?? email,
                  ),
              settings: const RouteSettings(name: '/bottom_navigation'),
            ),
          );
        }
      } else {
        throw l10n.loginFailedError;
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(l10n.errorLabel(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
                      _login();
                    }
                  },
                ),
      ),
    );
  }

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    _scrollController.dispose();
    _backgroundAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _gradientColorAnimation.value ??
                            theme.colorScheme.primary.withOpacity(0.2),
                        theme.colorScheme.secondary.withOpacity(0.2),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              },
            ),
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: screenHeight * 0.06,
                    bottom: screenHeight * 0.04,
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
                          userNameController,
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
                        _buildForgetPasswordLink(
                          theme,
                          l10n,
                        ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                        SizedBox(height: screenHeight * 0.03),
                        _buildLoginButton(
                          theme,
                          l10n,
                        ).animate().scale(duration: 500.ms, delay: 400.ms),
                        SizedBox(height: screenHeight * 0.02),
                        _buildRegisterLink(
                          theme,
                          l10n,
                        ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                        SizedBox(height: screenHeight * 0.06),
                        _buildGoogleSignInButton(
                          theme,
                          l10n,
                        ).animate().scale(duration: 500.ms, delay: 600.ms),
                        SizedBox(height: screenHeight * 0.04),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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

  Widget _buildProfileImage(ThemeData theme) {
    return Container(
      height: 120,
      width: 120,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage("assets/user.png"),
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

  Widget _buildWelcomeText(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.welcomeBack,
          style: theme.textTheme.displayMedium?.copyWith(
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

  Widget _buildForgetPasswordLink(ThemeData theme, AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordPage(),
                  settings: const RouteSettings(name: '/change_password'),
                ),
              ),
          child: Text(
            l10n.forgetPassword,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: theme.elevatedButtonTheme.style?.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 50)),
          elevation: WidgetStateProperty.resolveWith<double>(
            (states) => states.contains(WidgetState.pressed) ? 2 : 8,
          ),
          shadowColor: WidgetStatePropertyAll(
            theme.colorScheme.shadow.withOpacity(0.3),
          ),
        ),
        child:
            _isLoading
                ? CircularProgressIndicator(
                  color: theme.colorScheme.onPrimary,
                  strokeWidth: 4,
                )
                : Text(
                  l10n.logIn,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
      ),
    );
  }

  Widget _buildRegisterLink(ThemeData theme, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.noAccount,
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
                  builder: (context) => const RegisterPage(),
                  settings: const RouteSettings(name: '/register'),
                ),
              ),
          child: Text(
            l10n.register,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleSignInButton(ThemeData theme, AppLocalizations l10n) {
    return GestureDetector(
      onTap: _isLoading ? null : _nativeGoogleSignIn,
      child: Container(
        width: 225,
        decoration: BoxDecoration(
          border: Border.all(width: 1, color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(10),
          color: theme.colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/google.png", width: 24),
              const SizedBox(width: 10),
              Text(
                l10n.signInWithGoogle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
