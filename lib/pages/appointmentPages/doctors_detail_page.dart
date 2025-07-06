import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'booking_page.dart';
import 'dart:convert';

class DoctorDetailsPage extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailsPage({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          doctor['full_name'],
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                Semantics(
                  label: l10n.doctorProfile(
                    doctor['full_name'],
                    doctor['speciality'],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.onSurface.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: theme.colorScheme.primary
                              .withOpacity(0.2),
                          child: _buildProfileImage(
                            doctor['profile_url'],
                            theme,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          doctor['full_name'],
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          doctor['speciality'],
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 24,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.ratingLabel,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: l10n.aboutSection,
                  child: Text(
                    doctor['description'] ?? l10n.noDescriptionAvailable,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  theme: theme,
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: l10n.contactInformation,
                  child: Column(
                    children: [
                      _buildContactRow(
                        Icons.email,
                        l10n.emailLabel,
                        doctor['email'],
                        theme,
                      ),
                      _buildContactRow(
                        Icons.phone,
                        l10n.phoneLabel,
                        doctor['phone'] ?? l10n.notAvailable,
                        theme,
                      ),
                      _buildContactRow(
                        Icons.attach_money,
                        l10n.consultationsFee,
                        '\$${doctor['payment_required_amount']}',
                        theme,
                      ),
                    ],
                  ),
                  theme: theme,
                ),
                const SizedBox(height: 24),
                Semantics(
                  label: l10n.bookAppointmentWith(doctor['full_name']),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => BookingPage(doctorId: doctor['id']),
                        ),
                      );
                    },
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStatePropertyAll(
                        theme.colorScheme.primary,
                      ),
                      foregroundColor: WidgetStatePropertyAll(
                        theme.colorScheme.onPrimary,
                      ),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(vertical: 16),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      minimumSize: const WidgetStatePropertyAll(
                        Size(double.infinity, 56),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: theme.colorScheme.onPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.bookAppointment,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 10,
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? profileUrl, ThemeData theme) {
    if (profileUrl == null || profileUrl.isEmpty) {
      return Icon(Icons.person, size: 60, color: theme.colorScheme.primary);
    }

    if (profileUrl.startsWith('data:image/')) {
      // Handle base64 images
      try {
        // More robust base64 extraction
        final parts = profileUrl.split(',');
        if (parts.length < 2) {
          print('Invalid base64 format: missing comma separator');
          return Icon(Icons.person, size: 60, color: theme.colorScheme.primary);
        }

        final base64String = parts[1].trim();
        if (base64String.isEmpty) {
          print('Empty base64 string');
          return Icon(Icons.person, size: 60, color: theme.colorScheme.primary);
        }

        // Add padding if needed for proper base64 format
        String paddedBase64 = base64String;
        while (paddedBase64.length % 4 != 0) {
          paddedBase64 += '=';
        }

        final bytes = base64Decode(paddedBase64);
        print('Successfully decoded ${bytes.length} bytes');

        return ClipOval(
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              print('Image.memory error: $error');
              return Icon(
                Icons.person,
                size: 60,
                color: theme.colorScheme.primary,
              );
            },
          ),
        );
      } catch (e, stackTrace) {
        print('Base64 decode error: $e');
        print('Stack trace: $stackTrace');
        return Icon(Icons.person, size: 60, color: theme.colorScheme.primary);
      }
    } else {
      // Handle network URLs
      return ClipOval(
        child: Image.network(
          profileUrl,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) {
            print('Network image error: $error');
            return Icon(
              Icons.person,
              size: 60,
              color: theme.colorScheme.primary,
            );
          },
        ),
      );
    }
  }
}
