import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import 'doctors_detail_page.dart';

class DoctorCard extends StatelessWidget {
  final dynamic doctor;

  const DoctorCard({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Semantics(
      label: l10n.doctorProfile(
        doctor['full_name'] ?? l10n.unknownName,
        doctor['speciality'] ?? l10n.notSpecified,
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailsPage(doctor: doctor),
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: theme.cardTheme.elevation,
          shape:
              theme.cardTheme.shape ??
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: theme.cardTheme.color,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: _buildProfileImage(doctor['profile_url'], theme),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['full_name'] ?? l10n.unknownName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor['speciality'] ?? l10n.notSpecified,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
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
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? profileUrl, ThemeData theme) {
    if (profileUrl == null || profileUrl.isEmpty) {
      return Icon(Icons.person, size: 32, color: theme.colorScheme.primary);
    }

    if (profileUrl.startsWith('data:image/')) {
      // Handle base64 images
      try {
        // More robust base64 extraction
        final parts = profileUrl.split(',');
        if (parts.length < 2) {
          print('Invalid base64 format: missing comma separator');
          return Icon(Icons.person, size: 32, color: theme.colorScheme.primary);
        }

        final base64String = parts[1].trim();
        if (base64String.isEmpty) {
          print('Empty base64 string');
          return Icon(Icons.person, size: 32, color: theme.colorScheme.primary);
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
            width: 64,
            height: 64,
            errorBuilder: (context, error, stackTrace) {
              print('Image.memory error: $error');
              return Icon(
                Icons.person,
                size: 32,
                color: theme.colorScheme.primary,
              );
            },
          ),
        );
      } catch (e, stackTrace) {
        print('Base64 decode error: $e');
        print('Stack trace: $stackTrace');
        return Icon(Icons.person, size: 32, color: theme.colorScheme.primary);
      }
    } else {
      // Handle network URLs
      return ClipOval(
        child: Image.network(
          profileUrl,
          fit: BoxFit.cover,
          width: 64,
          height: 64,
          errorBuilder: (context, error, stackTrace) {
            print('Network image error: $error');
            return Icon(
              Icons.person,
              size: 32,
              color: theme.colorScheme.primary,
            );
          },
        ),
      );
    }
  }
}
