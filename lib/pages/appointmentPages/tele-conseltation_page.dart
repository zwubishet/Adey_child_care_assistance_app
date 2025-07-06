import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeleConsultationPage extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final String doctorName;

  const TeleConsultationPage({
    super.key,
    required this.appointment,
    required this.doctorName,
  });

  @override
  TeleConsultationPageState createState() => TeleConsultationPageState();
}

class TeleConsultationPageState extends State<TeleConsultationPage>
    with TickerProviderStateMixin {
  final JitsiMeet jitsiMeet = JitsiMeet();
  final supabase = Supabase.instance.client;
  bool isCallActive = false;
  String callStatus = 'Ready to join';
  late String roomName;
  late String meetingUrl;
  bool isJoining = false;
  String? errorMessage;
  Timer? _refreshTimer;
  bool _paymentVerified = false;
  RealtimeChannel? _appointmentChannel;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _verifyPaymentAndInitialize();
    _setupRealtimeSubscription();
    _slideController.forward();

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshAppointmentData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _appointmentChannel?.unsubscribe();
    _pulseController.dispose();
    _slideController.dispose();
    if (isCallActive) {
      try {
        jitsiMeet.hangUp();
      } catch (e) {
        debugPrint("Error hanging up: $e");
      }
    }
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final appointmentId = widget.appointment['id']?.toString();
    if (appointmentId == null) return;

    _appointmentChannel =
        supabase
            .channel('appointment-$appointmentId')
            .onPostgresChanges(
              event: PostgresChangeEvent.update,
              schema: 'public',
              table: 'appointments',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'id',
                value: appointmentId,
              ),
              callback: (payload) {
                if (mounted) {
                  _refreshAppointmentData();
                }
              },
            )
            .subscribe();
  }

  Future<void> _verifyPaymentAndInitialize() async {
    try {
      final appointmentId =
          widget.appointment['id']?.toString() ??
          widget.appointment['appointmentId']?.toString();

      if (appointmentId == null) {
        setState(() {
          errorMessage = 'Invalid appointment data';
        });
        return;
      }

      final response =
          await supabase
              .from('appointments')
              .select('payment_status, video_conference_link, status')
              .eq('id', appointmentId)
              .single();

      final paymentStatus = response['payment_status'];
      final status = response['status'];

      if (status != 'accepted') {
        setState(() {
          errorMessage = 'Appointment not accepted yet';
        });
        return;
      }

      if (paymentStatus != 'paid') {
        setState(() {
          errorMessage = 'Payment required for video call';
        });
        return;
      }

      _paymentVerified = true;
      await _initializeJitsiMeet();
    } catch (e) {
      debugPrint("Error verifying payment: $e");
      setState(() {
        errorMessage = 'Error verifying payment status';
      });
    }
  }

  Future<void> _refreshAppointmentData() async {
    if (!_paymentVerified) return;

    try {
      final appointmentId =
          widget.appointment['id']?.toString() ??
          widget.appointment['appointmentId']?.toString();
      if (appointmentId == null) return;

      final response =
          await supabase
              .from('appointments')
              .select('video_conference_link, status, payment_status')
              .eq('id', appointmentId)
              .single();

      if (mounted) {
        final newVideoLink = response['video_conference_link'];
        final status = response['status'];
        final paymentStatus = response['payment_status'];

        if (paymentStatus != 'paid') {
          _showPaymentIssueDialog();
          return;
        }

        if (status == 'cancelled') {
          _showAppointmentCancelledDialog();
          return;
        }

        if (newVideoLink != null &&
            newVideoLink.isNotEmpty &&
            newVideoLink != meetingUrl) {
          setState(() {
            meetingUrl = newVideoLink;
            roomName = _extractRoomNameFromUrl(meetingUrl);
          });

          if (!isCallActive) {
            _showNewLinkDialog();
          }
        }
      }
    } catch (e) {
      debugPrint("Error refreshing appointment data: $e");
    }
  }

  String _extractRoomNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : 'default_room';
    } catch (e) {
      return 'default_room';
    }
  }

  void _showPaymentIssueDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.red.shade50, Colors.red.shade100],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.payment_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Issue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'There seems to be an issue with your payment. Please contact support.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF7F8C8D)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showNewLinkDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.video_call,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n?.newMeetingLinkAvailable ??
                        'New Meeting Link Available',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.newMeetingLinkMessage ??
                        'A new meeting link is available. Would you like to join now?',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(l10n?.later ?? 'Later'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _joinMeeting();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            l10n?.joinNow ?? 'Join Now',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showAppointmentCancelledDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.red.shade50, Colors.red.shade100],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n?.appointmentCancelled ?? 'Appointment Cancelled',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.appointmentCancelledMessage ??
                        'This appointment has been cancelled.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        jitsiMeet.hangUp();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _initializeJitsiMeet() async {
    try {
      meetingUrl =
          widget.appointment['video_conference_link']?.toString() ?? '';

      if (meetingUrl.isNotEmpty) {
        roomName = _extractRoomNameFromUrl(meetingUrl);
      } else {
        final appointmentId =
            widget.appointment['id']?.toString() ??
            widget.appointment['appointmentId']?.toString() ??
            'default_room';
        roomName = 'caresync_appointment_$appointmentId';
        meetingUrl = 'https://meet.jit.si/$roomName';

        await _updateVideoLinkInDatabase(appointmentId, meetingUrl);
      }

      setState(() {
        callStatus = 'Ready to join - Tap the button below';
      });
    } catch (e) {
      debugPrint("Error in initializeJitsiMeet: $e");
      setState(() {
        errorMessage = 'Error initializing video call';
      });
    }
  }

  Future<void> _updateVideoLinkInDatabase(
    String appointmentId,
    String videoLink,
  ) async {
    try {
      if (appointmentId.isNotEmpty && appointmentId != 'default_room') {
        await supabase
            .from('appointments')
            .update({'video_conference_link': videoLink})
            .eq('id', appointmentId);
      }
    } catch (e) {
      debugPrint("Error updating video link in database: $e");
    }
  }

  Future<Map<String, String>> _getUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Patient';
      return {'name': userName};
    } catch (e) {
      return {'name': 'Patient'};
    }
  }

  Future<void> _joinMeeting() async {
    final l10n = AppLocalizations.of(context);

    if (!_paymentVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Payment required for video call'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (isJoining) return;

    setState(() {
      isJoining = true;
      callStatus = l10n?.joiningCall ?? 'Joining call...';
      errorMessage = null;
    });

    try {
      final userDetails = await _getUserDetails();

      var options = JitsiMeetConferenceOptions(
        serverURL: "https://meet.jit.si",
        room: roomName,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "subject": "Appointment with Dr. ${widget.doctorName}",
        },
        featureFlags: {
          "ios.recording.enabled": false,
          "live-streaming.enabled": false,
          "invite.enabled": false,
          "chat.enabled": true,
          "calendar.enabled": false,
          "call-integration.enabled": true,
          "pip.enabled": true,
        },
        userInfo: JitsiMeetUserInfo(displayName: userDetails['name']),
      );

      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          if (mounted) {
            setState(() {
              isCallActive = true;
              callStatus = l10n?.connectedToCall ?? 'Connected to call';
              isJoining = false;
            });
          }
        },
        conferenceTerminated: (url, error) {
          if (mounted) {
            setState(() {
              isCallActive = false;
              callStatus = 'Call ended';
              isJoining = false;
            });
          }
        },
        conferenceWillJoin: (url) {
          if (mounted) {
            setState(() {
              callStatus = l10n?.connectingToCall ?? 'Connecting to call...';
            });
          }
        },
      );

      await jitsiMeet.join(options, listener);
    } catch (error) {
      if (mounted) {
        setState(() {
          callStatus = l10n?.errorJoiningCall ?? 'Error joining call';
          errorMessage = error.toString();
          isJoining = false;
        });
      }
    }
  }

  String _formatAppointmentDate() {
    final l10n = AppLocalizations.of(context);
    try {
      final dateString =
          widget.appointment['appointmentDate'] ??
          widget.appointment['requested_time'] ??
          widget.appointment['requestedTime'];
      if (dateString == null) {
        return l10n?.noDateAvailable ?? 'No date available';
      }

      final date = DateTime.parse(dateString);
      return DateFormat('EEEE, MMMM d, yyyy - h:mm a').format(date);
    } catch (e) {
      return l10n?.invalidDateFormat ?? 'Invalid date format';
    }
  }

  void _copyToClipboard(String text) {
    final l10n = AppLocalizations.of(context);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.copiedToClipboard ?? 'Copied to clipboard'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final existingLink = widget.appointment['video_conference_link'];
    final hasExistingLink = existingLink != null && existingLink.isNotEmpty;
    final displayUrl = hasExistingLink ? existingLink : meetingUrl;

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
              icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                l10n?.videoConsultationTitle ?? 'Video Consultation',
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          SliverToBoxAdapter(
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Payment verification status
                    if (!_paymentVerified)
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.payment,
                                color: Colors.orange.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verifying Payment',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                  Text(
                                    'Please wait while we verify your payment...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Appointment info card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.video_call,
                                  color: Color(0xFF3498DB),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Video Consultation',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Dr. ${widget.doctorName}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scheduled Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatAppointmentDate(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                _paymentVerified
                                    ? Icons.check_circle
                                    : Icons.hourglass_empty,
                                color:
                                    _paymentVerified
                                        ? Colors.green
                                        : Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _paymentVerified
                                    ? 'Payment verified'
                                    : 'Verifying payment...',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      _paymentVerified
                                          ? Colors.green
                                          : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_paymentVerified) ...[
                      // Meeting information card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF3498DB),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  l10n?.meetingInformation ??
                                      'Meeting Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      displayUrl,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.colorScheme.primary,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    onPressed:
                                        () => _copyToClipboard(displayUrl),
                                    tooltip:
                                        l10n?.copyLinkTooltip ?? 'Copy link',
                                    color: const Color(0xFF3498DB),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Room: $roomName',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n?.yourDoctorWillJoin ??
                                  'Your doctor will join this meeting',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Error message
                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Error',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              errorMessage!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Call status
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isCallActive ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color:
                                  isCallActive
                                      ? Colors.green.shade50
                                      : _paymentVerified
                                      ? Colors.blue.shade50
                                      : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    isCallActive
                                        ? Colors.green.shade200
                                        : _paymentVerified
                                        ? Colors.blue.shade200
                                        : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        isCallActive
                                            ? Colors.green
                                            : _paymentVerified
                                            ? const Color(0xFF3498DB)
                                            : Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isCallActive
                                        ? Icons.videocam
                                        : _paymentVerified
                                        ? Icons.video_call
                                        : Icons.hourglass_empty,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        callStatus,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isCallActive
                                                  ? Colors.green.shade700
                                                  : _paymentVerified
                                                  ? const Color(0xFF3498DB)
                                                  : Colors.grey.shade700,
                                        ),
                                      ),
                                      if (isCallActive)
                                        Text(
                                          'You are now connected',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    if (_paymentVerified) ...[
                      // Join button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed:
                              isCallActive || isJoining ? null : _joinMeeting,
                          icon: Icon(
                            isJoining
                                ? Icons.hourglass_empty
                                : isCallActive
                                ? Icons.videocam
                                : Icons.video_call,
                            size: 24,
                          ),
                          label: Text(
                            isJoining
                                ? l10n?.joining ?? 'Joining...'
                                : isCallActive
                                ? l10n?.inCall ?? 'In Call'
                                : l10n?.joinVideoCall ?? 'Join Video Call',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isCallActive
                                    ? Colors.green
                                    : const Color(0xFF3498DB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Preparation checklist
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.checklist,
                                  color: Color(0xFF3498DB),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                l10n?.beforeJoining ?? 'Before joining:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildChecklistItem(
                            Icons.wifi,
                            l10n?.ensureStableConnection ??
                                'Ensure stable internet connection',
                          ),
                          _buildChecklistItem(
                            Icons.volume_off,
                            l10n?.findQuietSpace ?? 'Find a quiet space',
                          ),
                          _buildChecklistItem(
                            Icons.camera_alt,
                            l10n?.testCameraMic ??
                                'Test your camera and microphone',
                          ),
                          _buildChecklistItem(
                            Icons.quiz,
                            l10n?.haveQuestionsReady ??
                                'Have your questions ready',
                          ),
                          if (!_paymentVerified)
                            _buildChecklistItem(
                              Icons.payment,
                              'Payment must be completed before joining',
                              isWarning: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(
    IconData icon,
    String text, {
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  isWarning
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isWarning ? icon : Icons.check,
              color:
                  isWarning
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isWarning
                        ? Colors.orange.shade700
                        : const Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
