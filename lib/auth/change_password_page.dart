import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/component/input_fild.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isEmailSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = emailController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (email.isEmpty) {
      _showSnackBar(l10n.emptyEmailError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.adde://reset-password/',
      );

      setState(() {
        _isEmailSent = true;
        _isLoading = false;
      });

      _showSnackBar(l10n.resetEmailSentSuccess(email), isSuccess: true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(l10n.resetPasswordError(e.toString()));
    }
  }

  Future<void> _verifyOtpAndUpdatePassword() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (otp.isEmpty || newPassword.isEmpty) {
      _showSnackBar(l10n.emptyFieldsError);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar(l10n.passwordTooShortError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Verify OTP
      final authResponse = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );

      if (authResponse.session != null) {
        // Update password
        final updateResponse = await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: newPassword),
        );

        if (updateResponse.user != null) {
          setState(() => _isLoading = false);
          _showSnackBar(l10n.passwordUpdatedSuccess, isSuccess: true);
          // Optionally navigate to login page
          Navigator.of(context).pop();
        } else {
          throw Exception('Failed to update password');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(l10n.resetPasswordError(e.toString()));
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
        ),
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
                  textColor: theme.colorScheme.onError,
                  onPressed: () {
                    if (_isEmailSent) {
                      _verifyOtpAndUpdatePassword();
                    } else {
                      _sendPasswordResetEmail();
                    }
                  },
                ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.resetPasswordTitle,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.secondary.withOpacity(0.2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(screenHeight * 0.02),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.03),
                      _buildTitle(theme, l10n),
                      SizedBox(height: screenHeight * 0.015),
                      _buildDescription(theme, l10n),
                      SizedBox(height: screenHeight * 0.04),
                      _buildEmailInput(theme, l10n),
                      if (_isEmailSent) ...[
                        SizedBox(height: screenHeight * 0.03),
                        _buildOtpInput(theme, l10n),
                        SizedBox(height: screenHeight * 0.03),
                        _buildNewPasswordInput(theme, l10n),
                      ],
                      SizedBox(height: screenHeight * 0.03),
                      _buildActionButton(theme, l10n),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: theme.colorScheme.shadow.withOpacity(0.3),
                child: Center(
                  child: CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, AppLocalizations l10n) {
    return Text(
      l10n.resetPasswordHeader,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(ThemeData theme, AppLocalizations l10n) {
    return Text(
      _isEmailSent ? l10n.enterOtpDescription : l10n.resetPasswordDescription,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmailInput(ThemeData theme, AppLocalizations l10n) {
    return Semantics(
      label: l10n.emailLabel,
      child: InputField(
        controller: emailController,
        hintText: l10n.emailLabel,
        email: true,
        enabled: !_isEmailSent,
      ),
    );
  }

  Widget _buildOtpInput(ThemeData theme, AppLocalizations l10n) {
    return Semantics(
      label: l10n.otpLabel,
      child: InputField(
        controller: otpController,
        hintText: l10n.otpLabel,
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _buildNewPasswordInput(ThemeData theme, AppLocalizations l10n) {
    return Semantics(
      label: l10n.newPasswordLabel,
      child: InputField(
        controller: newPasswordController,
        hintText: l10n.newPasswordLabel,
        obscure: true,
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Semantics(
        label: _isEmailSent ? l10n.submitOtpButton : l10n.sendResetLinkButton,
        child: ElevatedButton(
          onPressed:
              _isLoading
                  ? null
                  : _isEmailSent
                  ? _verifyOtpAndUpdatePassword
                  : _sendPasswordResetEmail,
          style: theme.elevatedButtonTheme.style?.copyWith(
            minimumSize: const WidgetStatePropertyAll(
              Size(double.infinity, 50),
            ),
          ),
          child:
              _isLoading
                  ? CircularProgressIndicator(
                    color: theme.colorScheme.onPrimary,
                  )
                  : Text(
                    _isEmailSent
                        ? l10n.submitOtpButton
                        : l10n.sendResetLinkButton,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
        ),
      ),
    );
  }
}
