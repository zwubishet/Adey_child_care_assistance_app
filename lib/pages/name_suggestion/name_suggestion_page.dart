import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/name_suggestion/name_model.dart';
import 'package:adde/pages/name_suggestion/name_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NameSuggestionPage extends StatefulWidget {
  const NameSuggestionPage({super.key});

  @override
  _NameSuggestionPageState createState() => _NameSuggestionPageState();
}

class _NameSuggestionPageState extends State<NameSuggestionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Provider.of<NameProvider>(context, listen: false).fetchNames();
      setState(() {
        _isLoading = false;
        print('Initialized NameSuggestionPage');
      });
    } catch (e) {
      print('Error initializing NameSuggestionPage: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.errorLabel(e.toString()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final nameProvider = Provider.of<NameProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.pageTitleNameSuggestion,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color:
                theme.brightness == Brightness.light
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.primary,
          ),
        ),
        backgroundColor:
            theme.brightness == Brightness.light
                ? theme.colorScheme.surface
                : theme.colorScheme.onPrimary,
        elevation: theme.appBarTheme.elevation,
        bottom: TabBar(
          controller: _tabController,
          labelColor:
              theme.brightness == Brightness.light
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor:
              theme.brightness == Brightness.light
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onPrimary,
          labelStyle: theme.tabBarTheme.labelStyle?.copyWith(
            color:
                theme.brightness == Brightness.light
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onPrimary,
          ),
          unselectedLabelStyle: theme.tabBarTheme.unselectedLabelStyle
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          tabs: [
            Tab(text: l10n.tabAll),
            Tab(text: l10n.tabChristian),
            Tab(text: l10n.tabMuslim),
          ],
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              )
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildNameList(nameProvider.names, null),
                  _buildNameList(
                    nameProvider.names
                        .where((name) => name.religion == 'Christian')
                        .toList(),
                    'Christian',
                  ),
                  _buildNameList(
                    nameProvider.names
                        .where((name) => name.religion == 'Muslim')
                        .toList(),
                    'Muslim',
                  ),
                ],
              ),
    );
  }

  Widget _buildNameList(List<Name> names, String? religion) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final boys = names.where((name) => name.gender == 'Boy').toList();
    final girls = names.where((name) => name.gender == 'Girl').toList();

    return ListView(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
      children: [
        if (boys.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenHeight * 0.02,
              vertical: screenHeight * 0.01,
            ),
            child: Text(
              l10n.boysLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...boys.map((name) => _buildNameTile(name)),
        ],
        if (girls.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenHeight * 0.02,
              vertical: screenHeight * 0.01,
            ),
            child: Text(
              l10n.girlsLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...girls.map((name) => _buildNameTile(name)),
        ],
        if (boys.isEmpty && girls.isEmpty)
          Center(
            child: Text(
              l10n.noNamesAvailable(religion ?? l10n.tabAll),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNameTile(Name name) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenHeight * 0.02,
        vertical: screenHeight * 0.005,
      ),
      child: Card(
        color: theme.colorScheme.surfaceContainer,
        elevation: theme.cardTheme.elevation,
        shape:
            theme.cardTheme.shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            name.name,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            name.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Semantics(
            label: name.gender == 'Boy' ? l10n.maleGender : l10n.femaleGender,
            child: Icon(
              name.gender == 'Boy' ? Icons.male : Icons.female,
              color:
                  name.gender == 'Boy'
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}
