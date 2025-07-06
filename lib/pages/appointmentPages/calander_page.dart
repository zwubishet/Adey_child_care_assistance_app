import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';

import 'appointments_page.dart';
import 'booking_page.dart';
import 'doctors_page.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.motherAppTitle,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Semantics(
                  label: l10n.navigateToDoctors,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DoctorsPage(),
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
                      minimumSize: WidgetStatePropertyAll(
                        Size(screenWidth * 0.25, 48),
                      ),
                    ),
                    child: Text(
                      l10n.doctorsLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  label: l10n.navigateToBooking,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookingPage(doctorId: ''),
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
                      minimumSize: WidgetStatePropertyAll(
                        Size(screenWidth * 0.25, 48),
                      ),
                    ),
                    child: Text(
                      l10n.bookingLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                Semantics(
                  label: l10n.navigateToAppointments,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppointmentsPage(),
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
                      minimumSize: WidgetStatePropertyAll(
                        Size(screenWidth * 0.25, 48),
                      ),
                    ),
                    child: Text(
                      l10n.appointmentsLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                l10n.welcomeMessage,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
