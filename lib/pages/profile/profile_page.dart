import 'dart:convert';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/notification/NotificationSettingsProvider.dart';
import 'package:adde/pages/profile/ChangePasswordPage.dart';
import 'package:adde/pages/profile/locale_provider.dart';
import 'package:adde/pages/profile/profile_edit_page.dart';
import 'package:adde/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String? profileImageBase64;
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.noUserLoggedIn)));
        return;
      }

      final response =
          await supabase
              .from('mothers')
              .select()
              .eq('user_id', user.id)
              .single();

      setState(() {
        nameController.text = response['full_name'] ?? '';
        ageController.text = response['age']?.toString() ?? '';
        profileImageBase64 = response['profile_url'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToLoadProfile(e.toString()))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final notificationSettingsProvider =
        Provider.of<NotificationSettingsProvider>(context);
    final email = supabase.auth.currentUser?.email ?? 'No email';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.pageTitleProfile,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
              : FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Hero(
                                tag: 'profile-image',
                                child: CircleAvatar(
                                  radius: 70,
                                  backgroundImage:
                                      profileImageBase64 != null
                                          ? MemoryImage(
                                            base64Decode(profileImageBase64!),
                                          )
                                          : const AssetImage('assets/user.png')
                                              as ImageProvider,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.surface,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary
                                              .withOpacity(0.3),
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.3),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                email,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildProfileCard(
                          context,
                          icon: Icons.edit,
                          title: l10n.editProfile,
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  _createSlideRoute(const ProfileEditPage()),
                                )
                                .then((_) => _loadProfileData());
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildProfileCard(
                          context,
                          icon: Icons.lock,
                          title: l10n.changePassword,
                          onTap:
                              supabase.auth.currentUser == null
                                  ? null
                                  : () {
                                    Navigator.of(context).push(
                                      _createSlideRoute(
                                        const ChangePasswordPage(),
                                      ),
                                    );
                                  },
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                                Theme.of(context).colorScheme.primary,
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSwitchTile(
                          context,
                          icon:
                              themeProvider.isDarkMode
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                          title: l10n.themeMode,
                          value: themeProvider.isDarkMode,
                          onChanged:
                              (value) => themeProvider.toggleTheme(value),
                        ),
                        _buildSwitchTile(
                          context,
                          icon:
                              notificationSettingsProvider
                                      .showPopupNotifications
                                  ? Icons.notifications_active
                                  : Icons.notifications_off,
                          title: l10n.popupNotifications,
                          value:
                              notificationSettingsProvider
                                  .showPopupNotifications,
                          onChanged:
                              (value) => notificationSettingsProvider
                                  .togglePopupNotifications(value),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.languageSettings,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildLanguageButton(
                              context,
                              text: l10n.languageEnglish,
                              onPressed:
                                  () => localeProvider.setLocale(
                                    const Locale('en'),
                                  ),
                              delay: const Duration(milliseconds: 100),
                            ),
                            const SizedBox(width: 12),
                            _buildLanguageButton(
                              context,
                              text: l10n.languageAmharic,
                              onPressed:
                                  () => localeProvider.setLocale(
                                    const Locale('am'),
                                  ),
                              delay: const Duration(milliseconds: 200),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback? onTap,
  }) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 28,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Theme.of(context).colorScheme.outline,
            thumbColor: WidgetStateProperty.all(
              value
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    required Duration delay,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: Matrix4.translationValues(0, 0, 0),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.5, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              delay.inMilliseconds / 1000,
              1.0,
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 2,
          ),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
