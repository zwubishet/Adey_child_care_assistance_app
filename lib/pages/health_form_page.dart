import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/bottom_page_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MotherFormPage extends StatefulWidget {
  final String? email;
  final String? user_id;
  const MotherFormPage({super.key, required this.email, required this.user_id});

  @override
  State<MotherFormPage> createState() => _MotherFormPageState();
}

class _MotherFormPageState extends State<MotherFormPage> {
  String selectedGender = "Female";
  String selectedHeightUnit = "cm";
  int selectedAge = 18;
  String selectedWeightUnit = "kg";
  List<String> selectedHealthConditions = [];
  DateTime? pregnancyStartDate;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bloodPressureController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController healthInfoController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _bloodPressureFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _heightFocus = FocusNode();
  final FocusNode _healthInfoFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    bloodPressureController.dispose();
    weightController.dispose();
    heightController.dispose();
    healthInfoController.dispose();
    _scrollController.dispose();
    _nameFocus.dispose();
    _bloodPressureFocus.dispose();
    _weightFocus.dispose();
    _heightFocus.dispose();
    _healthInfoFocus.dispose();
    super.dispose();
  }

  Map<String, int> calculatePregnancyDuration(DateTime startDate) {
    final now = DateTime.now();
    final difference = now.difference(startDate);
    final weeks = (difference.inDays / 7).floor();
    final days = difference.inDays % 7;
    return {"weeks": weeks, "days": days};
  }

  Future<void> _selectPregnancyStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 280)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).colorScheme.primary,
                onPrimary: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null && picked != pregnancyStartDate) {
      setState(() => pregnancyStartDate = picked);
    }
  }

  void _showErrorDialog(String title, String message) {
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.successTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green.shade700,
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
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder:
                          (context) => BottomPageNavigation(
                            email: widget.email,
                            user_id: widget.user_id!,
                          ),
                    ),
                  );
                },
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
      barrierDismissible: false,
    );
  }

  void _confirmSubmit() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              l10n.confirmSubmissionTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            content: Text(
              l10n.confirmSubmissionMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.cancelButton,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  formSubmit();
                },
                child: Text(
                  l10n.submitButton,
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

  Future<void> formSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate() || pregnancyStartDate == null) {
      _showErrorDialog(l10n.errorTitle, l10n.requiredFieldsError);
      return;
    }

    final weight = double.tryParse(weightController.text.trim());
    final height = double.tryParse(heightController.text.trim());
    if (weight == null || height == null) {
      _showErrorDialog(l10n.errorTitle, l10n.invalidNumberError);
      return;
    }

    final pregnancyDuration = calculatePregnancyDuration(pregnancyStartDate!);
    final formData = {
      "user_id": widget.user_id,
      "email": widget.email,
      "full_name": nameController.text.trim(),
      "gender": selectedGender,
      "age": selectedAge,
      "weight": weight,
      "weight_unit": selectedWeightUnit,
      "height": height,
      "height_unit": selectedHeightUnit,
      "blood_pressure": bloodPressureController.text.trim(),
      "health_conditions": selectedHealthConditions,
      "health_info":
          healthInfoController.text.trim().isEmpty
              ? null
              : healthInfoController.text.trim(),
      "pregnancy_start_date": DateFormat(
        'yyyy-MM-dd',
      ).format(pregnancyStartDate!),
      "pregnancy_weeks": pregnancyDuration["weeks"],
      "pregnancy_days": pregnancyDuration["days"],
    };

    try {
      await Supabase.instance.client
          .from('mothers')
          .insert(formData)
          .select()
          .single();
      _showSuccessDialog(l10n.formSubmitSuccess);
    } catch (error) {
      _showErrorDialog(l10n.errorTitle, l10n.formSubmitError(error.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.motherFormTitle,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.2),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(screenHeight * 0.02),
          child: Card(
            elevation: theme.cardTheme.elevation,
            shape: theme.cardTheme.shape,
            color: theme.cardTheme.color,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.02,
                horizontal: screenHeight * 0.01,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameField(theme, l10n),
                      SizedBox(height: screenHeight * 0.02),
                      _buildGenderSection(theme, l10n),
                      SizedBox(height: screenHeight * 0.02),
                      _buildAgeSection(theme, l10n, screenHeight),
                      SizedBox(height: screenHeight * 0.02),
                      _buildHeightSection(theme, l10n),
                      SizedBox(height: screenHeight * 0.02),
                      _buildBloodPressureField(theme, l10n),
                      SizedBox(height: screenHeight * 0.02),
                      _buildWeightSection(theme, l10n),
                      SizedBox(height: screenHeight * 0.02),
                      _buildPregnancyStartDateSection(
                        theme,
                        l10n,
                        screenHeight,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildHealthConditionsSection(theme, l10n, screenHeight),
                      SizedBox(height: screenHeight * 0.02),
                      _buildSubmitButton(theme, l10n),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField(ThemeData theme, AppLocalizations l10n) {
    return Semantics(
      label: l10n.fullNameLabel,
      child: TextFormField(
        controller: nameController,
        focusNode: _nameFocus,
        decoration: InputDecoration(
          labelText: l10n.fullNameLabel,
          prefixIcon: Icon(Icons.person, color: theme.colorScheme.primary),
          border:
              theme.inputDecorationTheme.border ?? const OutlineInputBorder(),
          enabledBorder: theme.inputDecorationTheme.enabledBorder,
          focusedBorder: theme.inputDecorationTheme.focusedBorder,
          filled: theme.inputDecorationTheme.filled,
          fillColor:
              theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface,
        ),
        style: theme.textTheme.bodyMedium,
        textInputAction: TextInputAction.next,
        validator:
            (value) =>
                value!.trim().isEmpty ? l10n.fullNameRequiredError : null,
        onFieldSubmitted:
            (_) => FocusScope.of(context).requestFocus(_heightFocus),
      ),
    );
  }

  Widget _buildGenderSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectGenderLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: l10n.maleGenderOption,
                child: RadioListTile<String>(
                  title: Text(
                    l10n.maleGenderOption,
                    style: theme.textTheme.bodyMedium,
                  ),
                  value: "Male",
                  groupValue: selectedGender,
                  onChanged: null,
                  activeColor: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                label: l10n.femaleGenderOption,
                child: RadioListTile<String>(
                  title: Text(
                    l10n.femaleGenderOption,
                    style: theme.textTheme.bodyMedium,
                  ),
                  value: "Female",
                  groupValue: selectedGender,
                  onChanged: (value) => setState(() => selectedGender = value!),
                  activeColor: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeSection(
    ThemeData theme,
    AppLocalizations l10n,
    double screenHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectAgeLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: l10n.selectedAgeLabel(selectedAge),
          child: Slider(
            value: selectedAge.toDouble(),
            min: 18,
            max: 100,
            divisions: 82,
            label: selectedAge.round().toString(),
            onChanged: (value) => setState(() => selectedAge = value.toInt()),
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        Text(
          l10n.selectedAgeLabel(selectedAge),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildHeightSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.enterHeightLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: l10n.enterHeightLabel,
                child: TextFormField(
                  controller: heightController,
                  focusNode: _heightFocus,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.enterHeightLabel,
                    prefixIcon: Icon(
                      Icons.height,
                      color: theme.colorScheme.primary,
                    ),
                    border:
                        theme.inputDecorationTheme.border ??
                        const OutlineInputBorder(),
                    enabledBorder: theme.inputDecorationTheme.enabledBorder,
                    focusedBorder: theme.inputDecorationTheme.focusedBorder,
                    filled: theme.inputDecorationTheme.filled,
                    fillColor:
                        theme.inputDecorationTheme.fillColor ??
                        theme.colorScheme.surface,
                  ),
                  style: theme.textTheme.bodyMedium,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value!.trim().isEmpty) return l10n.heightRequiredError;
                    if (double.tryParse(value.trim()) == null) {
                      return l10n.heightInvalidError;
                    }
                    return null;
                  },
                  onFieldSubmitted:
                      (_) => FocusScope.of(context).requestFocus(_weightFocus),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              label: l10n.enterHeightLabel,
              child: DropdownButton<String>(
                value: selectedHeightUnit,
                items:
                    ["cm", "ft"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                onChanged:
                    (newValue) =>
                        setState(() => selectedHeightUnit = newValue!),
                style: theme.textTheme.bodyMedium,
                dropdownColor: theme.colorScheme.surface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBloodPressureField(ThemeData theme, AppLocalizations l10n) {
    return Semantics(
      label: l10n.bloodPressureLabel,
      child: TextFormField(
        controller: bloodPressureController,
        focusNode: _bloodPressureFocus,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          labelText: l10n.bloodPressureLabel,
          prefixIcon: Icon(
            Icons.monitor_heart,
            color: theme.colorScheme.primary,
          ),
          border:
              theme.inputDecorationTheme.border ?? const OutlineInputBorder(),
          enabledBorder: theme.inputDecorationTheme.enabledBorder,
          focusedBorder: theme.inputDecorationTheme.focusedBorder,
          filled: theme.inputDecorationTheme.filled,
          fillColor:
              theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surface,
        ),
        style: theme.textTheme.bodyMedium,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value!.trim().isEmpty) return l10n.bloodPressureRequiredError;
          if (!RegExp(r'^\d{2,3}/\d{2,3}$').hasMatch(value.trim())) {
            return l10n.bloodPressureInvalidError;
          }
          return null;
        },
        onFieldSubmitted:
            (_) => FocusScope.of(context).requestFocus(_healthInfoFocus),
      ),
    );
  }

  Widget _buildWeightSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.enterWeightLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: l10n.enterWeightLabel,
                child: TextFormField(
                  controller: weightController,
                  focusNode: _weightFocus,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.enterWeightLabel,
                    prefixIcon: Icon(
                      Icons.scale,
                      color: theme.colorScheme.primary,
                    ),
                    border:
                        theme.inputDecorationTheme.border ??
                        const OutlineInputBorder(),
                    enabledBorder: theme.inputDecorationTheme.enabledBorder,
                    focusedBorder: theme.inputDecorationTheme.focusedBorder,
                    filled: theme.inputDecorationTheme.filled,
                    fillColor:
                        theme.inputDecorationTheme.fillColor ??
                        theme.colorScheme.surface,
                  ),
                  style: theme.textTheme.bodyMedium,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value!.trim().isEmpty) return l10n.weightRequiredError;
                    if (double.tryParse(value.trim()) == null) {
                      return l10n.weightInvalidError;
                    }
                    return null;
                  },
                  onFieldSubmitted:
                      (_) => FocusScope.of(
                        context,
                      ).requestFocus(_bloodPressureFocus),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              label: l10n.enterWeightLabel,
              child: DropdownButton<String>(
                value: selectedWeightUnit,
                items:
                    ["kg", "lbs"].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: theme.textTheme.bodyMedium),
                      );
                    }).toList(),
                onChanged:
                    (newValue) =>
                        setState(() => selectedWeightUnit = newValue!),
                style: theme.textTheme.bodyMedium,
                dropdownColor: theme.colorScheme.surface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPregnancyStartDateSection(
    ThemeData theme,
    AppLocalizations l10n,
    double screenHeight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pregnancyStartDateQuestion,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          label: l10n.pregnancyStartDateLabel,
          child: GestureDetector(
            onTap: () => _selectPregnancyStartDate(context),
            child: AbsorbPointer(
              child: TextFormField(
                controller: TextEditingController(
                  text:
                      pregnancyStartDate != null
                          ? DateFormat('yyyy-MM-dd').format(pregnancyStartDate!)
                          : l10n.pregnancyStartDateNotSet,
                ),
                decoration: InputDecoration(
                  labelText: l10n.pregnancyStartDateLabel,
                  suffixIcon: Icon(
                    Icons.calendar_today,
                    color: theme.colorScheme.primary,
                  ),
                  border:
                      theme.inputDecorationTheme.border ??
                      const OutlineInputBorder(),
                  enabledBorder: theme.inputDecorationTheme.enabledBorder,
                  focusedBorder: theme.inputDecorationTheme.focusedBorder,
                  filled: theme.inputDecorationTheme.filled,
                  fillColor:
                      theme.inputDecorationTheme.fillColor ??
                      theme.colorScheme.surface,
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ),
        if (pregnancyStartDate != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.pregnancyDurationLabel(
              calculatePregnancyDuration(pregnancyStartDate!)['weeks']!,
              calculatePregnancyDuration(pregnancyStartDate!)['days']!,
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHealthConditionsSection(
    ThemeData theme,
    AppLocalizations l10n,
    double screenHeight,
  ) {
    final healthConditionLabels = {
      "Diabetes": l10n.healthConditionDiabetes,
      "Hypertension": l10n.healthConditionHypertension,
      "Asthma": l10n.healthConditionAsthma,
      "Heart Disease": l10n.healthConditionHeartDisease,
      "Thyroid Issues": l10n.healthConditionThyroidIssues,
      "Other": l10n.healthConditionOther,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.healthConditionsLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              healthConditionLabels.entries.map((entry) {
                final condition = entry.key;
                final label = entry.value;
                return Semantics(
                  label: "$label Health Condition Checkbox",
                  child: FilterChip(
                    label: Text(label, style: theme.textTheme.bodyMedium),
                    selected: selectedHealthConditions.contains(condition),
                    onSelected: (isSelected) {
                      setState(() {
                        if (isSelected) {
                          selectedHealthConditions.add(condition);
                        } else {
                          selectedHealthConditions.remove(condition);
                        }
                      });
                    },
                    selectedColor: theme.colorScheme.primary.withOpacity(0.3),
                    backgroundColor: theme.colorScheme.surfaceContainer,
                    checkmarkColor: theme.colorScheme.primary,
                  ),
                );
              }).toList(),
        ),
        if (selectedHealthConditions.contains("Other")) ...[
          SizedBox(height: screenHeight * 0.02),
          Text(
            l10n.healthIssueDescriptionLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: l10n.healthIssueDescriptionLabel,
            child: TextFormField(
              controller: healthInfoController,
              focusNode: _healthInfoFocus,
              maxLines: null,
              decoration: InputDecoration(
                hintText: l10n.healthIssueHint,
                prefixIcon: Icon(
                  Icons.health_and_safety,
                  color: theme.colorScheme.primary,
                ),
                border:
                    theme.inputDecorationTheme.border ??
                    const OutlineInputBorder(),
                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                focusedBorder: theme.inputDecorationTheme.focusedBorder,
                filled: theme.inputDecorationTheme.filled,
                fillColor:
                    theme.inputDecorationTheme.fillColor ??
                    theme.colorScheme.surface,
              ),
              style: theme.textTheme.bodyMedium,
              textInputAction: TextInputAction.done,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme, AppLocalizations l10n) {
    return Semantics(
      label: l10n.submitButton,
      child: ElevatedButton(
        onPressed: _confirmSubmit,
        style: theme.elevatedButtonTheme.style?.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 50)),
        ),
        child: Text(
          l10n.submitButton,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
