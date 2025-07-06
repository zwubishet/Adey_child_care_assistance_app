import 'package:adde/auth/register_page.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Welcome page widget for onboarding
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _backgroundAnimationController;
  Animation<Color?>?
  _gradientColorAnimation; // Non-late to handle initialization safely
  int _currentPage = 0;
  String? _lastLocale;

  static const List<String> _imagePaths = [
    'assets/woman.png',
    'assets/woman-1.png',
    'assets/notebook.png',
    'assets/community.png',
    'assets/chatbot-1.png',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize animation controller only
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
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
        // Log error internally and show user-friendly error
        debugPrint('Animation initialization failed: $e');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showErrorDialog('Failed to initialize onboarding animation.');
        });
      }
    }

    // Update state if locale changes
    if (_lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  // Show error dialog for in-app errors
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

  // Navigate to the registration page
  void _navigateToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterPage(),
        settings: const RouteSettings(name: '/register'),
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
      return _ErrorScreen(message: l10n.errorOnboardingMessage);
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
                        theme.colorScheme.secondary.withOpacity(0.2),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              },
            ),
            Column(
              children: [
                // PageView for onboarding slides
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _imagePaths.length,
                    onPageChanged:
                        (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      try {
                        return _buildPageContent(
                          theme,
                          l10n,
                          index,
                          screenHeight,
                        );
                      } catch (e) {
                        // Log error and show user-friendly error
                        debugPrint('Page content build failed: $e');
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _showErrorDialog(l10n.errorOnboardingMessage);
                        });
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
                // Navigation buttons and page indicators
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenHeight * 0.01,
                    vertical: screenHeight * 0.02,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAnimatedButton(
                        text: l10n.skipButton,
                        semanticsLabel: l10n.skipSemantics,
                        onPressed: _navigateToRegister,
                        theme: theme,
                      ).animate().scale(duration: 500.ms, delay: 400.ms),
                      Row(
                        children: List.generate(
                          _imagePaths.length,
                          (index) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              height: 8,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color:
                                    _currentPage == index
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface
                                            .withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow:
                                    _currentPage == index
                                        ? [
                                          BoxShadow(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                        : [],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 500.ms, delay: 500.ms),
                      _buildAnimatedButton(
                        text:
                            _currentPage == _imagePaths.length - 1
                                ? l10n.getStartedButton
                                : l10n.nextButton,
                        semanticsLabel:
                            _currentPage == _imagePaths.length - 1
                                ? l10n.getStartedSemantics
                                : l10n.nextSemantics,
                        onPressed: () {
                          if (_currentPage < _imagePaths.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutQuad,
                            );
                          } else {
                            _navigateToRegister();
                          }
                        },
                        theme: theme,
                      ).animate().scale(duration: 500.ms, delay: 600.ms),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build animated button widget
  Widget _buildAnimatedButton({
    required String text,
    required String semanticsLabel,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(100, 40),
        elevation: 8,
        shadowColor: theme.colorScheme.shadow.withOpacity(0.3),
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith<double>(
          (states) => states.contains(WidgetState.pressed) ? 2 : 8,
        ),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimary,
        ),
        semanticsLabel: semanticsLabel,
      ),
    );
  }

  // Build content for each onboarding page
  Widget _buildPageContent(
    ThemeData theme,
    AppLocalizations l10n,
    int index,
    double screenHeight,
  ) {
    final String title = index == 0 ? l10n.welcomePageTitle1 : '';
    final String content = switch (index) {
      0 => l10n.welcomePageContent1,
      1 => l10n.welcomePageContent2,
      2 => l10n.welcomePageContent3,
      3 => l10n.welcomePageContent4,
      4 => l10n.welcomePageContent5,
      _ => '',
    };

    return Semantics(
      label: l10n.onboardingPageSemantics(index + 1),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenHeight * 0.02),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (title.isNotEmpty) ...[
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
              SizedBox(height: screenHeight * 0.03),
            ],
            Container(
              height: screenHeight * 0.35,
              width: screenHeight * 0.4,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_imagePaths[index]),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ).animate().scale(
              duration: 600.ms,
              curve: Curves.easeOutBack,
              delay: 200.ms,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              content,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ).animate().slideY(
              begin: 0.2,
              end: 0,
              duration: 500.ms,
              delay: 300.ms,
            ),
          ],
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
