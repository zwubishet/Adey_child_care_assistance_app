import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/appointmentPages/doctors_page.dart';
import 'package:adde/pages/community/community_screen.dart';
import 'package:adde/pages/education/Education_page.dart';
import 'package:adde/pages/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class BottomPageNavigation extends StatefulWidget {
  final String? email;
  final String user_id;

  const BottomPageNavigation({
    super.key,
    required this.email,
    required this.user_id,
  });

  @override
  State<BottomPageNavigation> createState() => _BottomPageNavigationState();
}

class _BottomPageNavigationState extends State<BottomPageNavigation>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  DateTime? pregnancyStartDate;
  String? fullName;
  String? gender;
  int? age;
  double? weight;
  double? height;
  String? weightUnit;
  String? bloodPressure;
  List<String>? healthConditions;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMotherInfo();
  }

  Future<void> fetchMotherInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (widget.email == null) {
        throw Exception(AppLocalizations.of(context)!.emailNullError);
      }

      final response =
          await Supabase.instance.client
              .from('mothers')
              .select()
              .eq('email', widget.email!)
              .limit(1)
              .single();

      setState(() {
        fullName = response['full_name'] as String? ?? 'Unknown';
        gender = response['gender']?.toString() ?? 'N/A';
        age = response['age'] as int? ?? 0;
        weight =
            (response['weight'] is double)
                ? response['weight']
                : double.tryParse(response['weight']?.toString() ?? '0') ?? 0.0;
        height =
            (response['height'] is double)
                ? response['height']
                : double.tryParse(response['height']?.toString() ?? '0') ?? 0.0;
        weightUnit = response['weight_unit']?.toString() ?? 'kg';
        bloodPressure = response['blood_pressure']?.toString() ?? 'N/A';
        healthConditions =
            (response['health_conditions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        pregnancyStartDate =
            DateTime.tryParse(
              response['pregnancy_start_date']?.toString() ?? '',
            ) ??
            DateTime.now();
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog(
        AppLocalizations.of(context)!.errorTitle,
        AppLocalizations.of(context)!.errorLoadingData(error.toString()),
        retry: () => fetchMotherInfo(),
      );
    }
  }

  void _showErrorDialog(String title, String message, {VoidCallback? retry}) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            actions: [
              if (retry != null)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    retry();
                  },
                  child: Text(
                    AppLocalizations.of(context)!.retryButton,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  AppLocalizations.of(context)!.okButton,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 8,
          ),
      barrierDismissible: true,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final pages = [
      isLoading
          ? Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 3,
            ).animate().fadeIn(duration: 250.ms).scale(curve: Curves.easeOut),
          )
          : (fullName != null &&
              weight != null &&
              weightUnit != null &&
              height != null &&
              pregnancyStartDate != null)
          ? HomeScreen(
            user_id: widget.user_id,
            fullName: fullName!,
            weight: weight!,
            weightUnit: weightUnit!,
            height: height!,
            pregnancyStartDate: pregnancyStartDate!,
          )
          : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.failedToLoadUserData,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: fetchMotherInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    l10n.retryButton,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.easeOutQuad),
              ],
            ),
          ),
      const CommunityScreen(),
      const EducationPage(),
      const DoctorsPage(),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder:
                (child, animation) => FadeTransition(
                  opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
                  child: ScaleTransition(
                    scale: animation.drive(Tween(begin: 0.95, end: 1.0)),
                    child: child,
                  ),
                ),
            child: IndexedStack(
              key: ValueKey<int>(_selectedIndex),
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GNav(
              rippleColor: theme.colorScheme.primary.withOpacity(0.2),
              hoverColor: theme.colorScheme.primary.withOpacity(0.1),
              haptic: true,
              tabBorderRadius: 16,
              tabActiveBorder: Border.all(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
              tabBorder: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
                width: 1,
              ),
              tabShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                ),
              ],
              curve: Curves.easeInOutCubic,
              duration: const Duration(milliseconds: 600),
              gap: 6,
              color: theme.colorScheme.onSurfaceVariant,
              activeColor: theme.colorScheme.primary,
              iconSize: 24,
              tabBackgroundColor: theme.colorScheme.primary.withOpacity(0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
              tabs: [
                GButton(
                  icon:
                      _selectedIndex == 0 ? IconlyBold.home : IconlyLight.home,
                  text: l10n.bottomNavHome,
                  iconColor: theme.colorScheme.onSurfaceVariant,
                  iconActiveColor: theme.colorScheme.onPrimary,
                  textColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                ),
                GButton(
                  icon:
                      _selectedIndex == 1
                          ? IconlyBold.user2
                          : IconlyLight.user2,
                  text: l10n.bottomNavCommunity,
                  iconColor: theme.colorScheme.onSurfaceVariant,
                  iconActiveColor: theme.colorScheme.onPrimary,
                  textColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                ),
                GButton(
                  icon:
                      _selectedIndex == 2
                          ? IconlyBold.bookmark
                          : IconlyLight.bookmark,
                  text: l10n.bottomNavEducation,
                  iconColor: theme.colorScheme.onSurfaceVariant,
                  iconActiveColor: theme.colorScheme.onPrimary,
                  textColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                ),
                GButton(
                  icon:
                      _selectedIndex == 3 ? IconlyBold.call : IconlyLight.call,
                  text: l10n.bottomNavConsult,
                  iconColor: theme.colorScheme.onSurfaceVariant,
                  iconActiveColor: theme.colorScheme.onPrimary,
                  textColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ).animate().slideY(
        begin: 0.2,
        end: 0,
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      ),
    );
  }
}
