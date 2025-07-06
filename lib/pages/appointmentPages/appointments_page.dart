import 'package:flutter/material.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import 'payment_page.dart';
import 'tele-conseltation_page.dart';

class AppointmentsPage extends StatefulWidget {
  final String? doctorId;

  const AppointmentsPage({super.key, this.doctorId});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;
  RealtimeChannel? _appointmentsChannel;
  Timer? _refreshTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _fetchAppointmentsFromDatabase();
    _setupRealtimeSubscription();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _fetchAppointmentsFromDatabase();
      }
    });
  }

  @override
  void dispose() {
    _appointmentsChannel?.unsubscribe();
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _appointmentsChannel =
        Supabase.instance.client
            .channel('appointments-$userId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'appointments',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'mother_id',
                value: userId,
              ),
              callback: (payload) {
                if (mounted) {
                  _fetchAppointmentsFromDatabase();
                }
              },
            )
            .subscribe();
  }

  Future<void> _fetchAppointmentsFromDatabase() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final response = await Supabase.instance.client
          .from('appointments')
          .select('''
            *,
            doctors!appointments_doctor_id_fkey(
              id,
              full_name, 
              profile_url, 
              payment_required_amount,
              speciality,
              phone_number
            )
          ''')
          .eq('mother_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _appointments =
              response.isNotEmpty
                  ? List<Map<String, dynamic>>.from(response)
                  : [];
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (error) {
      debugPrint('Error fetching appointments: $error');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToVideoCall(Map<String, dynamic> appointment) async {
    final videoLink = appointment['video_conference_link'];
    if (videoLink != null && videoLink.isNotEmpty) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => TeleConsultationPage(
                appointment: appointment,
                doctorName: appointment['doctors']?['full_name'] ?? 'Doctor',
              ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
              ),
              child: child,
            );
          },
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.videoLinkNotAvailable),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _navigateToPayment(Map<String, dynamic> appointment) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final doctorData = appointment['doctors'] as Map<String, dynamic>?;

      if (doctorData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorLoadingPaymentData),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final motherResponse =
          await Supabase.instance.client
              .from('mothers')
              .select('full_name, email')
              .eq('user_id', userId)
              .single();

      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    AppointmentPaymentPage(
                      appointment: appointment,
                      doctorData: doctorData,
                      motherData: motherResponse,
                    ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                ),
                child: child,
              );
            },
          ),
        ).then((_) {
          if (mounted) {
            _fetchAppointmentsFromDatabase();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorLoadingPaymentData}: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(
    String? status,
    String? paymentStatus,
    bool hasVideoLink,
  ) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String statusText;

    if (status == 'accepted' && paymentStatus == 'unpaid') {
      backgroundColor = theme.colorScheme.error;
      textColor = theme.colorScheme.onError;
      icon = Icons.payment;
      statusText = 'Payment Required';
    } else if (status == 'accepted' &&
        paymentStatus == 'paid' &&
        !hasVideoLink) {
      backgroundColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
      icon = Icons.schedule;
      statusText = 'Waiting for Doctor';
    } else if (status == 'accepted' &&
        paymentStatus == 'paid' &&
        hasVideoLink) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
      icon = Icons.video_call;
      statusText = 'Ready to Join';
    } else if (status == 'completed') {
      backgroundColor = theme.colorScheme.outline;
      textColor = theme.colorScheme.onSurface;
      icon = Icons.check_circle;
      statusText = 'Completed';
    } else {
      backgroundColor = theme.colorScheme.surfaceContainerHighest;
      textColor = theme.colorScheme.onSurfaceVariant;
      icon = Icons.help_outline;
      statusText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment, int index) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final doctor = appointment['doctors'] as Map<String, dynamic>?;
    final status = appointment['status'];
    final paymentStatus = appointment['payment_status'];
    final hasVideoLink =
        appointment['video_conference_link'] != null &&
        appointment['video_conference_link'].isNotEmpty;
    final appointmentTime =
        DateTime.parse(appointment['requested_time'] as String).toLocal();
    final isUpcoming = appointmentTime.isAfter(DateTime.now());

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 20, top: index == 0 ? 20 : 0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.grey.shade50],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with date and status
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat(
                                      'EEEE, MMM d',
                                    ).format(appointmentTime),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat(
                                      'h:mm a',
                                    ).format(appointmentTime),
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(
                              status,
                              paymentStatus,
                              hasVideoLink,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Doctor information
                        if (doctor != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline.withOpacity(
                                  0.1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary.withOpacity(
                                          0.7,
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: ClipOval(
                                    child:
                                        doctor['profile_url'] != null
                                            ? Image.network(
                                              doctor['profile_url'],
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 30,
                                                  ),
                                            )
                                            : Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 30,
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctor['full_name'] ??
                                            l10n.unknownDoctor,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                      ),
                                      if (doctor['speciality'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          doctor['speciality'],
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                      if (doctor['payment_required_amount'] !=
                                          null) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '${doctor['payment_required_amount']} ETB',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Action buttons
                        if (paymentStatus == 'unpaid') ...[
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () => _navigateToPayment(appointment),
                              icon: const Icon(Icons.payment, size: 20),
                              label: Text(
                                l10n.payNow,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ] else if (paymentStatus == 'paid' &&
                            hasVideoLink &&
                            isUpcoming) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed:
                                  () => _navigateToVideoCall(appointment),
                              icon: const Icon(Icons.video_call, size: 20),
                              label: Text(
                                l10n.joinVideoCall,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ] else if (paymentStatus == 'paid' &&
                            !hasVideoLink) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.schedule,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Waiting for Doctor',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        'The doctor will provide the video link soon',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (!isUpcoming) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.history,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.appointmentCompleted,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
                onPressed: _fetchAppointmentsFromDatabase,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n.myAppointments,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child:
                _isLoading
                    ? SizedBox(
                      height: 400,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                    : _appointments.isEmpty
                    ? SizedBox(
                      height: 400,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                size: 60,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              l10n.noAppointmentsScheduled,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Book an appointment with a doctor to get started',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _fetchAppointmentsFromDatabase,
                      color: theme.colorScheme.primary,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _appointments.length,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemBuilder: (context, index) {
                          return _buildAppointmentCard(
                            _appointments[index],
                            index,
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
