import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyTipPage extends StatefulWidget {
  final Map<String, dynamic> initialTip;
  final DateTime pregnancyStartDate;

  const WeeklyTipPage({
    super.key,
    required this.initialTip,
    required this.pregnancyStartDate,
  });

  @override
  State<WeeklyTipPage> createState() => _WeeklyTipPageState();
}

class _WeeklyTipPageState extends State<WeeklyTipPage> {
  List<Map<String, dynamic>> _tips = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _currentWeek = 0;
  String? _lastLocale;

  @override
  void initState() {
    super.initState();
    print('Initial Tip on Init: ${widget.initialTip}');
    _calculateCurrentWeek();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context).languageCode;
    // Fetch tips if not loaded, on locale change, or after error
    if (_tips.isEmpty || _lastLocale != currentLocale || _hasError) {
      _loadTips();
      _lastLocale = currentLocale;
    }
  }

  void _calculateCurrentWeek() {
    final currentDate = DateTime.now();
    final difference = currentDate.difference(widget.pregnancyStartDate);
    final totalDays = difference.inDays;
    setState(() {
      _currentWeek = (totalDays / 7).floor();
    });
  }

  Future<void> _loadTips() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;
    final titleField = currentLocale == 'am' ? 'title_am' : 'title_en';
    final descriptionField =
        currentLocale == 'am' ? 'description_am' : 'description_en';
    print(
      'Locale: $currentLocale, Title Field: $titleField, Description Field: $descriptionField',
    );

    try {
      final supabase = Supabase.instance.client;

      // Check authentication status
      if (supabase.auth.currentUser == null) {
        throw Exception('User is not authenticated');
      }

      print('Fetching all tips from weekly_tips');
      final response = await supabase
          .from('weekly_tips')
          .select('id, week, $titleField, $descriptionField, image')
          .order('week', ascending: true)
          .timeout(const Duration(seconds: 10));
      print('Supabase response: $response');

      if (!mounted) return;

      final initialTipId = widget.initialTip['id'];
      final allTips =
          List<Map<String, dynamic>>.from(response).map((tip) {
            return {
              'id': tip['id'],
              'week': tip['week'] ?? 0,
              'title': tip[titleField] ?? l10n.noTitle,
              'description': tip[descriptionField] ?? l10n.noContent,
              'image': tip['image'],
              'locale': currentLocale,
            };
          }).toList();

      setState(() {
        if (initialTipId != null) {
          final matchedTip = allTips.firstWhere(
            (tip) => tip['id'] == initialTipId,
            orElse:
                () =>
                    Map<String, dynamic>.from(widget.initialTip)
                      ..['title'] ??= l10n.noTitle
                      ..['week'] ??= 0
                      ..['description'] ??= l10n.noContent
                      ..['locale'] = currentLocale,
          );
          _tips = [
            matchedTip,
            ...allTips.where((tip) => tip['id'] != initialTipId),
          ];
        } else {
          _tips = allTips;
        }
        print('Set _tips: $_tips');
      });
    } catch (e) {
      print('Error loading tips: $e');
      if (!mounted) return;

      setState(() {
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.errorLoadingEntries(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: l10n.retryButton,
            onPressed: _loadTips,
            textColor: Theme.of(context).colorScheme.onError,
          ),
        ),
      );

      setState(() {
        final initialTip = Map<String, dynamic>.from(widget.initialTip);
        initialTip['title'] ??= l10n.noTitle;
        initialTip['week'] ??= 0;
        initialTip['description'] ??= l10n.noContent;
        initialTip['locale'] = currentLocale;
        _tips = [initialTip];
        print('Fell back to initialTip: $_tips');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.pageTitleWeeklyTip,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor:
            Theme.of(context).brightness == Brightness.light
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.onPrimary,
        elevation: Theme.of(context).appBarTheme.elevation,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color:
                  Theme.of(context).brightness == Brightness.light
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.primary,
            ),
            onPressed: _loadTips,
            tooltip: l10n.retryButton,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    Theme.of(context).colorScheme.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Main Content
          RefreshIndicator(
            onRefresh: _loadTips,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                    : _hasError
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 60,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.errorLoadingEntries('Failed to load tips'),
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadTips,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                            ),
                            child: Text(l10n.retryButton),
                          ),
                        ],
                      ),
                    )
                    : _tips.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 60,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.noTipsYet,
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tips.length,
                      itemBuilder: (context, index) {
                        final tip = _tips[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: index == 0 ? 4 : 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: Theme.of(context).cardTheme.color,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tip['image'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      base64Decode(tip['image']),
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          width: double.infinity,
                                          height: 200,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.1),
                                          child: Icon(
                                            Icons.image,
                                            size: 60,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                if (tip['image'] != null)
                                  const SizedBox(height: 16),
                                Text(
                                  tip['title'] ?? l10n.noTitle,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  tip['description'] ?? l10n.noContent,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
