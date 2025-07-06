import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'appointments_page.dart';

class BookingPage extends StatefulWidget {
  final String doctorId;

  const BookingPage({super.key, required this.doctorId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final supabase = Supabase.instance.client;

  DateTime? _selectedDay;
  List<DateTime> _availableTimes = [];
  int? _currentTimeIndex;
  bool _timeSelected = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    try {
      await supabase.from('doctors').select('id').limit(1);
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
      }
    }
  }

  Future<void> _fetchAvailableTimes(DateTime selectedDate) async {
    final dateString = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final response =
          await supabase
              .from('doctor_availability')
              .select('availability')
              .eq('doctor_id', widget.doctorId)
              .maybeSingle();

      if (!mounted) return;

      if (response == null || response['availability'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.noAvailabilityFound,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      final availability = response['availability'];
      final dateEntry = (availability['dates'] as List?)?.firstWhere(
        (entry) => entry['date'] == dateString,
        orElse: () => null,
      );

      if (dateEntry != null) {
        setState(() {
          _availableTimes =
              (dateEntry['slots'] as List)
                  .map<DateTime>((slot) => DateFormat('HH:mm').parse(slot))
                  .toList();
        });
      } else {
        setState(() {
          _availableTimes = [];
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorLabel(error.toString()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _ensureMotherRecordExists() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return false;
    }

    try {
      final motherRecord =
          await supabase
              .from('mothers')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

      if (motherRecord != null) {
        return true;
      }

      final user = supabase.auth.currentUser!;
      final email = user.email ?? '';

      await supabase.from('mothers').insert({
        'user_id': userId,
        'full_name': email.split('@')[0],
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
      }
      return false;
    }
  }

  Future<void> sendRequest() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedDay == null || _currentTimeIndex == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.pleaseSelectDateTime,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final motherRecordExists = await _ensureMotherRecordExists();
      if (!motherRecordExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.couldNotCreateProfile,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final selectedTime = _availableTimes[_currentTimeIndex!];

      // Create the requested datetime in UTC to avoid timezone issues
      final requestedDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        selectedTime.hour,
        selectedTime.minute,
      );

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now().toUtc();
      final expiresAt = now.add(const Duration(minutes: 20));

      debugPrint('=== BOOKING TIME DEBUG ===');
      debugPrint('Selected date: $_selectedDay');
      debugPrint('Selected time: $selectedTime');
      debugPrint(
        'Requested DateTime (UTC): ${requestedDateTime.toIso8601String()}',
      );
      debugPrint('Current time (UTC): ${now.toIso8601String()}');

      await supabase
          .from('temporary_appointments')
          .insert({
            'doctor_id': widget.doctorId,
            'mother_id': userId,
            'requested_time': requestedDateTime.toIso8601String(),
            'expires_at': expiresAt.toIso8601String(),
            'status': 'pending',
          })
          .select()
          .single();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.requestSent,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentsPage(doctorId: widget.doctorId),
          ),
        );
      }

      setState(() {
        _selectedDay = null;
        _timeSelected = false;
        _currentTimeIndex = null;
        _availableTimes = [];
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.errorSendingRequest(error.toString()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.bookAppointment,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: theme.appBarTheme.foregroundColor,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : Column(
                children: [
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.all(8),
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color:
                        _isConnected
                            ? Colors.green.shade50
                            : theme.colorScheme.error.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.wifi : Icons.wifi_off,
                          color:
                              _isConnected
                                  ? Colors.green
                                  : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isConnected
                              ? l10n.connectedToServer
                              : l10n.notConnected,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                _isConnected
                                    ? Colors.green
                                    : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CalendarDatePicker(
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      onDateChanged: (date) {
                        setState(() {
                          _selectedDay = date;
                          _availableTimes = [];
                          _currentTimeIndex = null;
                          _timeSelected = false;
                        });
                        _fetchAvailableTimes(date);
                      },
                    ),
                  ),
                  if (_selectedDay != null) ...[
                    Text(
                      l10n.availableTimeSlots,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Container(
                      height: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _availableTimes.length,
                        itemBuilder: (context, index) {
                          final time = DateFormat(
                            'h:mm a',
                          ).format(_availableTimes[index]);
                          return ChoiceChip(
                            label: Text(
                              time,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    _currentTimeIndex == index
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface,
                              ),
                            ),
                            selected: _currentTimeIndex == index,
                            selectedColor: theme.colorScheme.primary,
                            backgroundColor: theme.colorScheme.surfaceContainer,
                            onSelected: (selected) {
                              setState(() {
                                _currentTimeIndex = selected ? index : null;
                                _timeSelected = selected;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  const Spacer(),
                  ElevatedButton(
                    onPressed:
                        _selectedDay != null && _timeSelected
                            ? sendRequest
                            : null,
                    style: theme.elevatedButtonTheme.style?.copyWith(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) =>
                            states.contains(WidgetState.disabled)
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.primary,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) =>
                            states.contains(WidgetState.disabled)
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onPrimary,
                      ),
                    ),
                    child: Text(
                      l10n.requestAppointment,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color:
                            _selectedDay != null && _timeSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
    );
  }
}
