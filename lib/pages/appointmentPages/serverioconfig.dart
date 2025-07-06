import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Storage keys for appointments
  static const pendingAppointmentsKey = 'pending_appointments';
  static const acceptedAppointmentsKey = 'accepted_appointments';
  static const declinedAppointmentsKey = 'declined_appointments';

  // Supabase client
  final supabase = Supabase.instance.client;

  // Realtime channels
  RealtimeChannel? _appointmentsChannel;
  RealtimeChannel? _tempAppointmentsChannel;
  RealtimeChannel? _notificationsChannel;

  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Callbacks
  Function(bool)? onConnectionChange;
  Function(String)? onError;
  Function(List<Map<String, dynamic>>)? onAppointmentHistoryReceived;
  Function(Map<String, dynamic>)? onAppointmentAccepted;
  Function(Map<String, dynamic>)? onAppointmentDeclined;
  Function(Map<String, dynamic>)? onPaymentConfirmed;
  Function(Map<String, dynamic>)? onNotificationReceived;

  // Connect to Supabase realtime
  void connect(String userId) async {
    try {
      // Check if already connected
      if (_isConnected) {
        return;
      }

      // Set up realtime subscription for appointments table (accepted appointments)
      _appointmentsChannel =
          supabase
              .channel('appointments-$userId')
              .onPostgresChanges(
                event: PostgresChangeEvent.insert,
                schema: 'public',
                table: 'appointments',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'mother_id',
                  value: userId,
                ),
                callback: (payload) {
                  // Handle new appointment (when moved from temporary to permanent)
                  final appointment = payload.newRecord;
                  if (onAppointmentAccepted != null) {
                    onAppointmentAccepted!({
                      'appointmentId': appointment['id'],
                      'doctorId': appointment['doctor_id'],
                      'requestedTime': appointment['requested_time'],
                      'status': appointment['status'],
                      'paymentStatus': appointment['payment_status'],
                      'videoLink': appointment['video_conference_link'],
                    });
                  }
                },
              )
              .onPostgresChanges(
                event: PostgresChangeEvent.update,
                schema: 'public',
                table: 'appointments',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'mother_id',
                  value: userId,
                ),
                callback: (payload) {
                  // Handle updated appointment (payment status, video link, etc.)
                  final appointment = payload.newRecord;

                  // Check if payment was confirmed
                  if (appointment['payment_status'] == 'paid' &&
                      appointment['video_conference_link'] != null) {
                    if (onPaymentConfirmed != null) {
                      onPaymentConfirmed!({
                        'appointmentId': appointment['id'],
                        'doctorId': appointment['doctor_id'],
                        'requestedTime': appointment['requested_time'],
                        'videoLink': appointment['video_conference_link'],
                        'paymentStatus': appointment['payment_status'],
                      });
                    }
                  }
                },
              )
              .subscribe();

      // Set up realtime subscription for temporary appointments
      _tempAppointmentsChannel =
          supabase
              .channel('temp-appointments-$userId')
              .onPostgresChanges(
                event: PostgresChangeEvent.delete,
                schema: 'public',
                table: 'temporary_appointments',
                callback: (payload) {
                  // A temporary appointment was deleted (accepted, rejected, or expired)
                  requestAppointmentHistory(userId, 'mother');
                },
              )
              .subscribe();

      // Set up realtime subscription for notifications
      _notificationsChannel =
          supabase
              .channel('notifications-$userId')
              .onPostgresChanges(
                event: PostgresChangeEvent.insert,
                schema: 'public',
                table: 'notifications',
                filter: PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'recipient_id',
                  value: userId,
                ),
                callback: (payload) {
                  // Handle new notification
                  final notification = payload.newRecord;
                  if (onNotificationReceived != null) {
                    onNotificationReceived!(notification);
                  }
                },
              )
              .subscribe();

      // Update connection status
      _isConnected = true;
      if (onConnectionChange != null) {
        onConnectionChange!(true);
      }

      // Load initial appointment history
      requestAppointmentHistory(userId, 'mother');
    } catch (error) {
      _isConnected = false;
      if (onConnectionChange != null) {
        onConnectionChange!(false);
      }
      if (onError != null) {
        onError!(error.toString());
      }
    }
  }

  // Disconnect from Supabase realtime
  void disconnect() {
    _appointmentsChannel?.unsubscribe();
    _tempAppointmentsChannel?.unsubscribe();
    _notificationsChannel?.unsubscribe();
    _isConnected = false;
    if (onConnectionChange != null) {
      onConnectionChange!(false);
    }
  }

  // Request appointment history
  Future<void> requestAppointmentHistory(String userId, String userType) async {
    try {
      List<Map<String, dynamic>> appointments = [];

      if (userType == 'mother') {
        // Fetch temporary appointments (pending requests)
        final tempAppointments = await supabase
            .from('temporary_appointments')
            .select('''
              id,
              mother_id,
              doctor_id,
              requested_time,
              created_at,
              expires_at,
              status,
              doctors!temporary_appointments_doctor_id_fkey (
                id,
                full_name,
                speciality,
                profile_url,
                payment_required_amount
              )
            ''')
            .eq('mother_id', userId)
            .order('created_at', ascending: false);

        // Add temporary appointments as pending
        for (var appointment in tempAppointments) {
          final Map<String, dynamic> appointmentData = {
            'appointmentId': appointment['id'],
            'motherId': appointment['mother_id'],
            'doctorId': appointment['doctor_id'],
            'requestedTime': appointment['requested_time'],
            'createdAt': appointment['created_at'],
            'expiresAt': appointment['expires_at'],
            'status': 'pending', // Always pending for temp appointments
            'type': 'temporary',
            'doctor_name':
                appointment['doctors'] != null
                    ? appointment['doctors']['full_name']
                    : 'Unknown Doctor',
            'doctor_speciality':
                appointment['doctors'] != null
                    ? appointment['doctors']['speciality']
                    : null,
            'payment_amount':
                appointment['doctors'] != null
                    ? appointment['doctors']['payment_required_amount']
                    : null,
          };
          appointments.add(appointmentData);
        }

        // Fetch regular appointments (accepted and paid)
        final regularAppointments = await supabase
            .from('appointments')
            .select('''
              id,
              mother_id,
              doctor_id,
              requested_time,
              status,
              payment_status,
              video_conference_link,
              created_at,
              updated_at,
              doctors!appointments_doctor_id_fkey (
                id,
                full_name,
                speciality,
                profile_url,
                payment_required_amount
              )
            ''')
            .eq('mother_id', userId)
            .order('created_at', ascending: false);

        // Add regular appointments
        for (var appointment in regularAppointments) {
          final Map<String, dynamic> appointmentData = {
            'appointmentId': appointment['id'],
            'motherId': appointment['mother_id'],
            'doctorId': appointment['doctor_id'],
            'requestedTime': appointment['requested_time'],
            'createdAt': appointment['created_at'],
            'updatedAt': appointment['updated_at'],
            'status': appointment['status'],
            'paymentStatus': appointment['payment_status'],
            'videoLink': appointment['video_conference_link'],
            'type': 'permanent',
            'doctor_name':
                appointment['doctors'] != null
                    ? appointment['doctors']['full_name']
                    : 'Unknown Doctor',
            'doctor_speciality':
                appointment['doctors'] != null
                    ? appointment['doctors']['speciality']
                    : null,
            'payment_amount':
                appointment['doctors'] != null
                    ? appointment['doctors']['payment_required_amount']
                    : null,
          };
          appointments.add(appointmentData);
        }
      } else if (userType == 'doctor') {
        // Similar logic for doctors but with different filters
        // Fetch temporary appointments for doctor
        final tempAppointments = await supabase
            .from('temporary_appointments')
            .select('''
              id,
              mother_id,
              doctor_id,
              requested_time,
              created_at,
              expires_at,
              status,
              mothers!temporary_appointments_mother_id_fkey (
                user_id,
                full_name,
                profile_url
              )
            ''')
            .eq('doctor_id', userId)
            .order('created_at', ascending: false);

        // Add temporary appointments as pending
        for (var appointment in tempAppointments) {
          final Map<String, dynamic> appointmentData = {
            'appointmentId': appointment['id'],
            'motherId': appointment['mother_id'],
            'doctorId': appointment['doctor_id'],
            'requestedTime': appointment['requested_time'],
            'createdAt': appointment['created_at'],
            'expiresAt': appointment['expires_at'],
            'status': 'pending',
            'type': 'temporary',
            'mother_name':
                appointment['mothers'] != null
                    ? appointment['mothers']['full_name']
                    : 'Unknown Mother',
          };
          appointments.add(appointmentData);
        }

        // Fetch regular appointments for doctor
        final regularAppointments = await supabase
            .from('appointments')
            .select('''
              id,
              mother_id,
              doctor_id,
              requested_time,
              status,
              payment_status,
              video_conference_link,
              created_at,
              updated_at,
              mothers!appointments_mother_id_fkey (
                user_id,
                full_name,
                profile_url
              )
            ''')
            .eq('doctor_id', userId)
            .order('created_at', ascending: false);

        // Add regular appointments
        for (var appointment in regularAppointments) {
          final Map<String, dynamic> appointmentData = {
            'appointmentId': appointment['id'],
            'motherId': appointment['mother_id'],
            'doctorId': appointment['doctor_id'],
            'requestedTime': appointment['requested_time'],
            'createdAt': appointment['created_at'],
            'updatedAt': appointment['updated_at'],
            'status': appointment['status'],
            'paymentStatus': appointment['payment_status'],
            'videoLink': appointment['video_conference_link'],
            'type': 'permanent',
            'mother_name':
                appointment['mothers'] != null
                    ? appointment['mothers']['full_name']
                    : 'Unknown Mother',
          };
          appointments.add(appointmentData);
        }
      }

      // Save to local storage
      await _saveAppointmentsToStorage(appointments);

      // Notify listeners
      if (onAppointmentHistoryReceived != null) {
        onAppointmentHistoryReceived!(appointments);
      }
    } catch (error) {
      if (onError != null) {
        onError!('Failed to fetch appointments: $error');
      }
    }
  }

  // Request an appointment (creates temporary appointment)
  Future<Map<String, dynamic>> requestAppointment(
    String motherId,
    String doctorId,
    String requestedTime,
  ) async {
    try {
      // Calculate expires_at (20 minutes from now)
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 20));

      // Create a temporary appointment
      final response =
          await supabase
              .from('temporary_appointments')
              .insert({
                'mother_id': motherId,
                'doctor_id': doctorId,
                'requested_time': requestedTime,
                'created_at': now.toIso8601String(),
                'expires_at': expiresAt.toIso8601String(),
                'status': 'pending',
              })
              .select()
              .single();

      return {
        'success': true,
        'appointmentId': response['id'],
        'message': 'Appointment request sent successfully',
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to request appointment: $error',
      };
    }
  }

  // Accept an appointment (for doctors) - moves from temporary to permanent
  Future<Map<String, dynamic>> acceptAppointment(
    String appointmentId,
    String videoLink,
  ) async {
    try {
      // First update the temporary appointment status to 'processing'
      await supabase
          .from('temporary_appointments')
          .update({'status': 'processing'})
          .eq('id', appointmentId);

      // Get the temporary appointment
      final tempAppointment =
          await supabase
              .from('temporary_appointments')
              .select()
              .eq('id', appointmentId)
              .single();

      // Create a permanent appointment with unpaid status
      await supabase.from('appointments').insert({
        'mother_id': tempAppointment['mother_id'],
        'doctor_id': tempAppointment['doctor_id'],
        'requested_time': tempAppointment['requested_time'],
        'status': 'accepted',
        'payment_status': 'unpaid', // Payment required
        'video_conference_link': null, // Will be set after payment
      });

      // Delete the temporary appointment
      await supabase
          .from('temporary_appointments')
          .delete()
          .eq('id', appointmentId);

      return {'success': true, 'message': 'Appointment accepted successfully'};
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to accept appointment: $error',
      };
    }
  }

  // Decline an appointment (for doctors)
  Future<Map<String, dynamic>> declineAppointment(String appointmentId) async {
    try {
      // First update the temporary appointment status to 'processing'
      await supabase
          .from('temporary_appointments')
          .update({'status': 'processing'})
          .eq('id', appointmentId);

      // Delete the temporary appointment
      await supabase
          .from('temporary_appointments')
          .delete()
          .eq('id', appointmentId);

      return {'success': true, 'message': 'Appointment declined successfully'};
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to decline appointment: $error',
      };
    }
  }

  // Save appointments to local storage
  Future<void> _saveAppointmentsToStorage(
    List<Map<String, dynamic>> appointments,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Separate appointments by status and type
      List<Map<String, dynamic>> pending = [];
      List<Map<String, dynamic>> accepted = [];
      List<Map<String, dynamic>> declined = [];

      for (var appointment in appointments) {
        String status = appointment['status'] ?? 'pending';
        String type = appointment['type'] ?? 'permanent';

        if (status == 'pending' || status == 'processing') {
          pending.add(appointment);
        } else if (status == 'accepted') {
          accepted.add(appointment);
        } else if (status == 'declined' || status == 'cancelled') {
          declined.add(appointment);
        }
      }

      // Save to SharedPreferences
      await prefs.setString(pendingAppointmentsKey, jsonEncode(pending));
      await prefs.setString(acceptedAppointmentsKey, jsonEncode(accepted));
      await prefs.setString(declinedAppointmentsKey, jsonEncode(declined));
    } catch (error) {
      // Ignore storage errors
    }
  }

  // Load appointments from local storage
  Future<Map<String, List<Map<String, dynamic>>>>
  loadAppointmentsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get stored appointments
      final pendingJson = prefs.getString(pendingAppointmentsKey) ?? '[]';
      final acceptedJson = prefs.getString(acceptedAppointmentsKey) ?? '[]';
      final declinedJson = prefs.getString(declinedAppointmentsKey) ?? '[]';

      // Parse JSON
      List<Map<String, dynamic>> pending = List<Map<String, dynamic>>.from(
        jsonDecode(pendingJson).map((item) => Map<String, dynamic>.from(item)),
      );

      List<Map<String, dynamic>> accepted = List<Map<String, dynamic>>.from(
        jsonDecode(acceptedJson).map((item) => Map<String, dynamic>.from(item)),
      );

      List<Map<String, dynamic>> declined = List<Map<String, dynamic>>.from(
        jsonDecode(declinedJson).map((item) => Map<String, dynamic>.from(item)),
      );

      return {'pending': pending, 'accepted': accepted, 'declined': declined};
    } catch (error) {
      // Return empty lists on error
      return {'pending': [], 'accepted': [], 'declined': []};
    }
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
    } catch (error) {
      // Ignore errors
    }
  }
}
