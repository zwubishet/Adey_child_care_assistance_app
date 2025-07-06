import 'dart:convert';
import 'dart:io';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  _ProfileEditPageState createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController bloodPressureController = TextEditingController();
  final TextEditingController healthInfoController = TextEditingController();

  String? profileImageBase64;
  String? selectedGender;
  String? selectedWeightUnit;
  String? selectedHeightUnit;
  DateTime? pregnancyStartDate;

  List<String> selectedHealthConditions = [];
  final List<String> healthConditionsKeys = [
    "diabetes",
    "hypertension",
    "asthma",
    "heartDisease",
    "thyroidIssues",
    "other",
  ];
  final List<String> genderOptions = ["female", "male", "other"];
  final supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  bool _isLoading = false;
  bool _isImageLoading = false;
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _shakeAnimation;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticIn),
    );
    _animationController.forward();
    _loadProfileData();
  }

  String _getLocalizedGender(String gender, AppLocalizations l10n) {
    switch (gender) {
      case 'female':
        return l10n.genderFemale;
      case 'male':
        return l10n.genderMale;
      case 'other':
        return l10n.genderOther;
      default:
        return l10n.genderFemale;
    }
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response =
            await supabase
                .from('mothers')
                .select()
                .eq('user_id', user.id)
                .single();

        setState(() {
          nameController.text = response['full_name'] ?? '';
          ageController.text = response['age']?.toString() ?? '';
          weightController.text = response['weight']?.toString() ?? '';
          heightController.text = response['height']?.toString() ?? '';
          bloodPressureController.text = response['blood_pressure'] ?? '';
          healthInfoController.text = response['health_info'] ?? '';
          profileImageBase64 = response['profile_url'];
          selectedGender =
              genderOptions.contains(response['gender'])
                  ? response['gender']
                  : "female";
          selectedWeightUnit =
              ["kg", "lbs"].contains(response['weight_unit'])
                  ? response['weight_unit']
                  : "kg";
          selectedHeightUnit =
              ["cm", "ft"].contains(response['height_unit'])
                  ? response['height_unit']
                  : "cm";
          pregnancyStartDate = DateTime.tryParse(
            response['pregnancy_start_date'] ?? '',
          );

          final healthConditionsData = response['health_conditions'];
          if (healthConditionsData != null) {
            if (healthConditionsData is String) {
              selectedHealthConditions =
                  healthConditionsData
                      .split(',')
                      .where((condition) => condition.isNotEmpty)
                      .toList();
            } else if (healthConditionsData is List<dynamic>) {
              selectedHealthConditions =
                  healthConditionsData
                      .map((condition) => condition.toString())
                      .where((condition) => condition.isNotEmpty)
                      .toList();
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToLoadProfile(e.toString()),
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      _animationController.forward(from: 0); // Trigger shake animation
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception(AppLocalizations.of(context)!.noUserLoggedIn);
      }

      final updates = {
        "email": user.email,
        'user_id': user.id,
        'full_name': nameController.text,
        'gender': selectedGender,
        'age': int.tryParse(ageController.text) ?? 0,
        'weight': double.tryParse(weightController.text) ?? 0.0,
        'weight_unit': selectedWeightUnit,
        'height': double.tryParse(heightController.text) ?? 0.0,
        'height_unit': selectedHeightUnit,
        'blood_pressure': bloodPressureController.text,
        'profile_url': profileImageBase64,
        'pregnancy_start_date':
            pregnancyStartDate != null
                ? DateFormat('yyyy-MM-dd').format(pregnancyStartDate!)
                : null,
        'health_conditions': selectedHealthConditions,
        'health_info': healthInfoController.text,
      };

      await supabase.from('mothers').upsert(updates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.profileUpdatedSuccessfully,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      String errorMessage;
      if (e is PostgrestException) {
        errorMessage = e.message;
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error: Please check your internet connection.';
      } else {
        errorMessage = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.failedToUpdateProfile(errorMessage),
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> pickImage(ImageSource source) async {
    PermissionStatus status;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isImageLoading = true);

    try {
      if (source == ImageSource.camera) {
        status = await Permission.camera.request();
      } else {
        final androidVersion =
            Platform.isAndroid ? await _getAndroidVersion() : 0;
        if (Platform.isAndroid && androidVersion >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }
      }

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? l10n.cameraPermissionDenied
                  : l10n.galleryPermissionDenied,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        if (status.isPermanentlyDenied) openAppSettings();
        return;
      }

      final pickedImage = await _picker.pickImage(
        source: source,
        maxHeight: 300,
        maxWidth: 300,
      );
      if (pickedImage == null) return;

      final file = File(pickedImage.path);
      final bytes = await file.readAsBytes();
      if (bytes.length > 500 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.imageTooLarge,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }

      final base64Image = base64Encode(bytes);
      setState(() {
        profileImageBase64 = base64Image;
      });
    } catch (e) {
      String errorMessage = e.toString();
      if (e.toString().contains('camera_unavailable')) {
        errorMessage = 'Camera is not available on this device.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorPickingImage(errorMessage),
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isImageLoading = false);
    }
  }

  Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.version.sdkInt ?? 0;
      }
    } catch (e) {
      print('Error getting Android version: $e');
    }
    return 0;
  }

  Future<void> _selectPregnancyStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: pregnancyStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != pregnancyStartDate) {
      setState(() {
        pregnancyStartDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final email = supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.editProfileTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
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
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isDarkMode
                                    ? [
                                      Theme.of(context).colorScheme.surface,
                                      Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                                    ]
                                    : [
                                      Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.2),
                                      Theme.of(context).colorScheme.surface,
                                    ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                    top: Radius.circular(12),
                                                  ),
                                            ),
                                            builder:
                                                (context) => SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(0, 1),
                                                    end: Offset.zero,
                                                  ).animate(
                                                    CurvedAnimation(
                                                      parent:
                                                          _animationController,
                                                      curve: Curves.easeOut,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      ListTile(
                                                        leading: Icon(
                                                          Icons.photo_library,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                        title: Text(
                                                          l10n.chooseFromGallery,
                                                          style: Theme.of(
                                                                context,
                                                              )
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                color:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .onSurface,
                                                              ),
                                                        ),
                                                        onTap: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          pickImage(
                                                            ImageSource.gallery,
                                                          );
                                                        },
                                                      ),
                                                      ListTile(
                                                        leading: Icon(
                                                          Icons.camera_alt,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                        title: Text(
                                                          l10n.takePhoto,
                                                          style: Theme.of(
                                                                context,
                                                              )
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.copyWith(
                                                                color:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .onSurface,
                                                              ),
                                                        ),
                                                        onTap: () {
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          pickImage(
                                                            ImageSource.camera,
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          );
                                        },
                                        child: Hero(
                                          tag: 'profile-image',
                                          child: Stack(
                                            alignment: Alignment.bottomRight,
                                            children: [
                                              CircleAvatar(
                                                radius: 70,
                                                backgroundImage:
                                                    profileImageBase64 != null
                                                        ? MemoryImage(
                                                          base64Decode(
                                                            profileImageBase64!,
                                                          ),
                                                        )
                                                        : const AssetImage(
                                                              'assets/user.png',
                                                            )
                                                            as ImageProvider,
                                                backgroundColor:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.surface,
                                                child:
                                                    profileImageBase64 == null
                                                        ? Icon(
                                                          Icons.person,
                                                          size: 80,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                        )
                                                        : null,
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.edit,
                                                  color:
                                                      Theme.of(
                                                        context,
                                                      ).colorScheme.onPrimary,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (_isImageLoading)
                                        CircularProgressIndicator(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    email,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: Text(
                                    l10n.personalInformation,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: nameController,
                                  label: l10n.fullNameLabel,
                                  icon: Icons.person,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.fullNameError;
                                    }
                                    return null;
                                  },
                                  delay: 0.1,
                                ),
                                const SizedBox(height: 16),
                                _buildDropdownField(
                                  value: selectedGender,
                                  items: genderOptions,
                                  label: l10n.genderLabel,
                                  itemBuilder:
                                      (value) =>
                                          _getLocalizedGender(value, l10n),
                                  onChanged:
                                      (newValue) => setState(
                                        () => selectedGender = newValue!,
                                      ),
                                  validator:
                                      (value) =>
                                          value == null
                                              ? l10n.genderSelectionError
                                              : null,
                                  delay: 0.2,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: ageController,
                                  label: l10n.ageLabel,
                                  icon: Icons.calendar_today,
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.ageEmptyError;
                                    }
                                    final age = int.tryParse(value);
                                    if (age == null || age < 0 || age > 120) {
                                      return l10n.ageInvalidError;
                                    }
                                    return null;
                                  },
                                  delay: 0.3,
                                ),
                                const SizedBox(height: 16),
                                _buildMeasurementField(
                                  controller: weightController,
                                  label: l10n.weightLabel,
                                  icon: Icons.scale,
                                  unitValue: selectedWeightUnit,
                                  unitItems: ["kg", "lbs"],
                                  unitLabelBuilder:
                                      (value) => l10n.weightUnit(value),
                                  onUnitChanged:
                                      (newValue) => setState(
                                        () => selectedWeightUnit = newValue!,
                                      ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.weightEmptyError;
                                    }
                                    final weight = double.tryParse(value);
                                    if (weight == null || weight <= 0) {
                                      return l10n.weightInvalidError;
                                    }
                                    return null;
                                  },
                                  delay: 0.4,
                                ),
                                const SizedBox(height: 16),
                                _buildMeasurementField(
                                  controller: heightController,
                                  label: l10n.heightLabel,
                                  icon: Icons.height,
                                  unitValue: selectedHeightUnit,
                                  unitItems: ["cm", "ft"],
                                  unitLabelBuilder:
                                      (value) => l10n.heightUnit(value),
                                  onUnitChanged:
                                      (newValue) => setState(
                                        () => selectedHeightUnit = newValue!,
                                      ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.heightEmptyError;
                                    }
                                    final height = double.tryParse(value);
                                    if (height == null || height <= 0) {
                                      return l10n.heightInvalidError;
                                    }
                                    return null;
                                  },
                                  delay: 0.5,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: bloodPressureController,
                                  label: l10n.bloodPressureLabel,
                                  icon: Icons.monitor_heart,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return l10n.bloodPressureEmptyError;
                                    }
                                    if (!RegExp(
                                      r'^\d{2,3}/\d{2,3}$',
                                    ).hasMatch(value)) {
                                      return l10n.bloodPressureInvalidError;
                                    }
                                    return null;
                                  },
                                  delay: 0.6,
                                ),
                                const SizedBox(height: 16),
                                _buildDateField(
                                  label: l10n.pregnancyStartDateLabel,
                                  date: pregnancyStartDate,
                                  onTap:
                                      () => _selectPregnancyStartDate(context),
                                  validator:
                                      (value) =>
                                          pregnancyStartDate == null
                                              ? l10n.pregnancyStartDateError
                                              : null,
                                  delay: 0.7,
                                ),
                                const SizedBox(height: 24),
                                SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: const Interval(
                                        0.8,
                                        1.0,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.selectHealthConditions,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children:
                                      healthConditionsKeys.map((conditionKey) {
                                        return AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeInOut,
                                          child: FilterChip(
                                            label: Text(
                                              l10n.healthCondition(
                                                conditionKey,
                                              ),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                              ),
                                            ),
                                            selected: selectedHealthConditions
                                                .contains(conditionKey),
                                            onSelected: (isSelected) {
                                              setState(() {
                                                if (isSelected) {
                                                  selectedHealthConditions.add(
                                                    conditionKey,
                                                  );
                                                } else {
                                                  selectedHealthConditions
                                                      .remove(conditionKey);
                                                }
                                              });
                                            },
                                            selectedColor: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withOpacity(0.3),
                                            backgroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                            checkmarkColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                            elevation:
                                                selectedHealthConditions
                                                        .contains(conditionKey)
                                                    ? 2
                                                    : 0,
                                          ),
                                        );
                                      }).toList(),
                                ),
                                if (selectedHealthConditions.contains(
                                  "other",
                                )) ...[
                                  const SizedBox(height: 16),
                                  SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: const Interval(
                                          0.9,
                                          1.0,
                                          curve: Curves.easeOut,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.describeHealthIssue,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: healthInfoController,
                                    label: l10n.healthIssueHint,
                                    icon: Icons.health_and_safety,
                                    maxLines: null,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return l10n.healthIssueEmptyError;
                                      }
                                      return null;
                                    },
                                    delay: 1.0,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: const Interval(
                                        1.0,
                                        1.0,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _updateProfile,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 2,
                                      minimumSize: const Size(
                                        double.infinity,
                                        50,
                                      ),
                                    ),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeInOut,
                                      transform:
                                          Matrix4.identity()
                                            ..scale(_isLoading ? 0.95 : 1.0),
                                      child: Text(
                                        l10n.saveProfileButton,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLines,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    required double delay,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Transform.translate(
        offset: Offset(
          validator!(controller.text) != null &&
                  _formKey.currentState?.validate() == false
              ? _shakeAnimation.value
              : 0,
          0,
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            labelText: label,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> items,
    required String label,
    required String Function(String) itemBuilder,
    required ValueChanged<String?> onChanged,
    required String? Function(String?)? validator,
    required double delay,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Transform.translate(
        offset: Offset(
          validator!(value) != null &&
                  _formKey.currentState?.validate() == false
              ? _shakeAnimation.value
              : 0,
          0,
        ),
        child: DropdownButtonFormField<String>(
          value: value,
          items:
              items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    itemBuilder(item),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            labelText: label,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            prefixIcon: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          validator: validator,
        ),
      ),
    );
  }

  Widget _buildMeasurementField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? unitValue,
    required List<String> unitItems,
    required String Function(String) unitLabelBuilder,
    required ValueChanged<String?> onUnitChanged,
    required String? Function(String?)? validator,
    required double delay,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Transform.translate(
        offset: Offset(
          validator!(controller.text) != null &&
                  _formKey.currentState?.validate() == false
              ? _shakeAnimation.value
              : 0,
          0,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                      width: 2,
                    ),
                  ),
                  labelText: label,
                  labelStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                validator: validator,
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: unitValue,
              items:
                  unitItems.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        unitLabelBuilder(value),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: onUnitChanged,
              underline: Container(
                height: 2,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required String? Function(String?)? validator,
    required double delay,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay, 1.0, curve: Curves.easeOut),
        ),
      ),
      child: Transform.translate(
        offset: Offset(
          validator!(null) != null && _formKey.currentState?.validate() == false
              ? _shakeAnimation.value
              : 0,
          0,
        ),
        child: TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 2,
              ),
            ),
            labelText: label,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            prefixIcon: Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
          ),
          controller: TextEditingController(
            text: date != null ? DateFormat('yyyy-MM-dd').format(date) : '',
          ),
          onTap: onTap,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          validator: validator,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    bloodPressureController.dispose();
    healthInfoController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
