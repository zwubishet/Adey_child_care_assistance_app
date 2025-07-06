import 'dart:convert';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/chatbot/chat_screen.dart';
import 'package:adde/pages/health_matrics_page.dart';
import 'package:adde/pages/name_suggestion/name_suggestion_page.dart';
import 'package:adde/pages/note/journal_screen.dart';
import 'package:adde/pages/notification/NotificationSettingsProvider.dart';
import 'package:adde/pages/notification/notificatio_history_page.dart';
import 'package:adde/pages/notification/notification_service.dart';
import 'package:adde/pages/weekly_tips/weeklytip_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/auth/login_page.dart';
import 'package:adde/pages/profile/profile_page.dart';
import 'package:adde/pages/profile/locale_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class HomeScreen extends StatefulWidget {
  final String user_id;
  final String fullName;
  final double weight;
  final String weightUnit;
  final double height;
  final DateTime pregnancyStartDate;

  const HomeScreen({
    super.key,
    required this.user_id,
    required this.fullName,
    required this.weight,
    required this.weightUnit,
    required this.height,
    required this.pregnancyStartDate,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late AnimationController _backgroundAnimationController;
  late Animation<Color?> _gradientColorAnimation;
  bool _hasUnreadNotifications = false;
  int _pregnancyWeeks = 0;
  int _pregnancyDays = 0;
  String? _profileImageBase64;
  List<Map<String, dynamic>> _weeklyTips = [];
  bool _hasShownTodaysTip = false;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _updatePregnancyProgress();
    _loadProfileImage();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkUnreadNotifications();
        _scheduleHealthTips();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_hasShownTodaysTip) {
            _checkAndShowTodaysTip();
            _hasShownTodaysTip = true;
          }
        });
      }
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

    if (_lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      _loadWeeklyTips();
    }

    _gradientColorAnimation = ColorTween(
      begin: theme.colorScheme.primary.withOpacity(0.1),
      end: theme.colorScheme.secondary.withOpacity(0.1),
    ).animate(
      CurvedAnimation(
        parent: _backgroundAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  void _updatePregnancyProgress() {
    final currentDate = DateTime.now();
    final difference = currentDate.difference(widget.pregnancyStartDate);
    final totalDays = difference.inDays;
    setState(() {
      _pregnancyWeeks = (totalDays / 7).floor();
      _pregnancyDays = totalDays % 7;
    });
  }

  Future<void> _loadProfileImage() async {
    try {
      final response = await Supabase.instance.client
          .from('mothers')
          .select('profile_url')
          .eq('user_id', widget.user_id)
          .single()
          .timeout(const Duration(seconds: 10));
      setState(() {
        _profileImageBase64 = response['profile_url'];
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorDialog(
          l10n.errorTitle,
          l10n.errorLoadingProfileImage(e.toString()),
        );
      }
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      final locale = AppLocalizations.of(context)!.localeName;
      final history = await notificationService.getNotificationHistory(
        widget.user_id,
        locale,
      );
      setState(() {
        _hasUnreadNotifications = history.any((n) => n['seen'] == false);
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorDialog(
          l10n.errorTitle,
          l10n.errorCheckingNotifications(e.toString()),
        );
      }
    }
  }

  Future<void> _scheduleHealthTips() async {
    try {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      final l10n = AppLocalizations.of(context)!;
      final locale = l10n.localeName;
      await notificationService.scheduleDailyHealthTips(
        widget.pregnancyStartDate,
        widget.user_id,
        locale,
        l10n.notificationChannelName,
        l10n.notificationChannelDescription,
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorDialog(
          l10n.errorTitle,
          l10n.errorSchedulingTips(e.toString()),
        );
      }
    }
  }

  Future<void> _checkAndShowTodaysTip() async {
    try {
      final notificationService = Provider.of<NotificationService>(
        context,
        listen: false,
      );
      final notificationSettingsProvider =
          Provider.of<NotificationSettingsProvider>(context, listen: false);
      final l10n = AppLocalizations.of(context)!;
      final locale = l10n.localeName;

      await notificationService.checkAndShowTodaysTip(
        widget.user_id,
        widget.pregnancyStartDate,
        locale,
        l10n.notificationChannelName,
        l10n.notificationChannelDescription,
        showPopup: notificationSettingsProvider.showPopupNotifications,
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        _showErrorDialog(
          l10n.errorTitle,
          l10n.errorLoadingEntries(e.toString()),
          retry: _checkAndShowTodaysTip,
        );
      }
    }
  }

  Future<void> _loadWeeklyTips() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response = await Supabase.instance.client
          .from('weekly_tips')
          .select('id, week, title_en, title_am, image')
          .order('week', ascending: true)
          .limit(3)
          .timeout(const Duration(seconds: 10));

      setState(() {
        _weeklyTips =
            List<Map<String, dynamic>>.from(response).map((tip) {
              return {
                'id': tip['id'],
                'week': tip['week'],
                'title_en': tip['title_en'] ?? l10n.noTitle,
                'title_am': tip['title_am'] ?? l10n.noTitle,
                'image': tip['image'],
              };
            }).toList();
      });
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          l10n.errorTitle,
          l10n.errorLoadingEntries(e.toString()),
          retry: _loadWeeklyTips,
        );
      }
    }
  }

  _showErrorDialog(String title, String message, {VoidCallback? retry}) {
    return print(title);
    // showDialog(
    //   context: context,
    //   builder:
    //       (context) => AlertDialog(
    //         title: Text(
    //           title,
    //           style: Theme.of(context).textTheme.titleLarge?.copyWith(
    //             color: Theme.of(context).colorScheme.error,
    //             fontWeight: FontWeight.bold,
    //           ),
    //         ),
    //         content: Text(
    //           message,
    //           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
    //             color: Theme.of(context).colorScheme.onSurface,
    //           ),
    //         ),
    //         actions: [
    //           if (retry != null)
    //             TextButton(
    //               onPressed: () {
    //                 Navigator.pop(context);
    //                 retry();
    //               },
    //               child: Text(
    //                 AppLocalizations.of(context)!.retryButton,
    //                 style: Theme.of(context).textTheme.labelLarge?.copyWith(
    //                   color: Theme.of(context).colorScheme.primary,
    //                 ),
    //               ),
    //             ),
    //           TextButton(
    //             onPressed: () => Navigator.pop(context),
    //             child: Text(
    //               AppLocalizations.of(context)!.okButton,
    //               style: Theme.of(context).textTheme.labelLarge?.copyWith(
    //                 color: Theme.of(context).colorScheme.primary,
    //               ),
    //             ),
    //           ),
    //         ],
    //         shape: RoundedRectangleBorder(
    //           borderRadius: BorderRadius.circular(12),
    //         ),
    //         backgroundColor: Theme.of(context).colorScheme.surface,
    //         elevation: 8,
    //       ),
    //   barrierDismissible: true,
    // );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildAppBar(context),
        floatingActionButton: _buildFloatingActionButton(context),
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
                            theme.colorScheme.primary.withOpacity(0.1),
                        theme.colorScheme.surface,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                );
              },
            ),
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.02),
                    child: _buildPregnancyJourneySection(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: _buildWeeklyTipsSection(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _buildFeaturesSection(
                        context,
                      ).map((widget) => widget).toList(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: screenHeight * 0.1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor:
          isDarkMode ? theme.colorScheme.onPrimary : theme.colorScheme.surface,
      elevation: 0,
      title: Row(
        children: [
          Semantics(
            child: GestureDetector(
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ).then((_) => _loadProfileImage()),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.surfaceContainer,
                backgroundImage:
                    _profileImageBase64 != null
                        ? MemoryImage(base64Decode(_profileImageBase64!))
                        : const AssetImage('assets/user.png') as ImageProvider,
                child:
                    _profileImageBase64 == null
                        ? Icon(
                          Icons.person,
                          color:
                              isDarkMode
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                        )
                        : null,
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutCubic),
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(
                IconlyLight.notification,
                color:
                    isDarkMode
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                size: 30,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => NotificationHistoryPage(userId: widget.user_id),
                  ),
                );
                await _checkUnreadNotifications();
              },
            ).animate().scale(duration: 400.ms, delay: 200.ms),
            if (_hasUnreadNotifications)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 1,
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              ),
          ],
        ),
        IconButton(
          icon: Icon(
            IconlyLight.logout,
            color:
                isDarkMode
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
            size: 30,
          ),
          onPressed: () async {
            try {
              await Supabase.instance.client.auth.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('supabase_session');
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            } catch (e) {
              if (mounted) {
                final l10n = AppLocalizations.of(context)!;
                _showErrorDialog(
                  l10n.errorTitle,
                  l10n.errorLoggingOut(e.toString()),
                  retry: () async {
                    await Supabase.instance.client.auth.signOut();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('supabase_session');
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  },
                );
              }
            }
          },
        ).animate().scale(duration: 400.ms, delay: 400.ms),
      ],
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final theme = Theme.of(context);
    return FloatingActionButton(
      onPressed:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          ),
      backgroundColor: theme.colorScheme.primary,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Icon(
        IconlyLight.chat,
        color: theme.colorScheme.onPrimary,
        size: 24,
      ),
    ).animate().scale(
      duration: 400.ms,
      curve: Curves.easeOutCubic,
      delay: 500.ms,
    );
  }

  Widget _buildPregnancyJourneySection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 35),
      margin: const EdgeInsets.only(top: 38),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.pregnancyJourney,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCounterBox(_pregnancyWeeks, l10n.weeksLabel, 200.ms),
              const SizedBox(width: 16),
              CircleAvatar(
                radius: 60,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: ClipOval(
                  child: Image.asset(
                    "assets/embryo.gif",
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  ),
                ),
              ).animate().scale(
                duration: 400.ms,
                curve: Curves.easeOutCubic,
                delay: 300.ms,
              ),
              const SizedBox(width: 16),
              _buildCounterBox(_pregnancyDays, l10n.daysLabel, 400.ms),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (_pregnancyWeeks / 40).clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ).animate().slideX(
                    duration: 400.ms,
                    delay: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyTipsSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final currentLocale = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.weeklyTips,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child:
              _weeklyTips.isEmpty
                  ? Center(
                    child: Text(
                      l10n.noTipsYet,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _weeklyTips.length,
                    itemBuilder: (context, index) {
                      final tip = _weeklyTips[index];
                      final title =
                          currentLocale == 'am'
                              ? tip['title_am']
                              : tip['title_en'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => WeeklyTipPage(
                                      initialTip: tip,
                                      pregnancyStartDate:
                                          widget.pregnancyStartDate,
                                    ),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              width: 220,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child:
                                        tip['image'] != null
                                            ? Image.memory(
                                              base64Decode(tip['image']),
                                              height: 100,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              frameBuilder: (
                                                context,
                                                child,
                                                frame,
                                                wasSynchronouslyLoaded,
                                              ) {
                                                return child.animate().fadeIn(
                                                  duration: 400.ms,
                                                  delay: (index * 200).ms,
                                                );
                                              },
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    height: 100,
                                                    color: theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.1),
                                                    child: Icon(
                                                      IconlyLight.image,
                                                      size: 40,
                                                      color:
                                                          theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                                  ),
                                            )
                                            : Container(
                                              height: 150,
                                              color: theme.colorScheme.onSurface
                                                  .withOpacity(0.1),
                                              child: Icon(
                                                IconlyLight.image,
                                                size: 40,
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          title ?? l10n.noTitle,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                          maxLines: 1,
                                          softWrap: true,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 400.ms,
                          delay: (index * 200).ms,
                          curve: Curves.easeOutCubic,
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  List<Widget> _buildFeaturesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Theme.of(context);

    final features = [
      {
        "icon": IconlyLight.heart,
        "name": l10n.featureHealthMetrics,
        "description": l10n.featureHealthMetricsDescription,
        "navigation":
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HealthMetricsPage(userId: widget.user_id),
              ),
            ),
      },
      {
        "icon": IconlyLight.document,
        "name": l10n.featureJournal,
        "description": l10n.featureJournalDescription,
        "navigation":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JournalScreen()),
            ),
      },
      {
        "icon": IconlyLight.star,
        "name": l10n.featureNameSuggestion,
        "description": l10n.featureNameSuggestionDescription,
        "navigation":
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NameSuggestionPage()),
            ),
      },
    ];

    return features.asMap().entries.map((entry) {
      final index = entry.key;
      final feature = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildFeatureCard(feature, index),
      );
    }).toList();
  }

  Widget _buildCounterBox(int value, String label, Duration delay) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            "$value",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ).animate().fadeIn(
      duration: 400.ms,
      delay: delay,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, int index) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: feature["navigation"],
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature["icon"],
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature["name"],
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature["description"],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                IconlyLight.arrowRight,
                size: 20,
                color: theme.colorScheme.primary,
              ).animate().scale(duration: 400.ms, delay: 100.ms),
            ],
          ),
        ),
      ),
    ).animate().slideY(
      begin: 0.2,
      end: 0,
      duration: 400.ms,
      delay: (index * 200).ms,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }
}
