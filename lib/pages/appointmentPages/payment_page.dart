import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AppointmentPaymentPage extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic> doctorData;
  final Map<String, dynamic> motherData;

  const AppointmentPaymentPage({
    super.key,
    required this.appointment,
    required this.doctorData,
    required this.motherData,
  });

  @override
  State<AppointmentPaymentPage> createState() => _AppointmentPaymentPageState();
}

class _AppointmentPaymentPageState extends State<AppointmentPaymentPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late WebViewController _webViewController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool isLoading = false;
  bool isPaymentComplete = false;
  String? errorMessage;
  String? checkoutUrl;
  String? txRef;
  Timer? _statusTimer;
  RealtimeChannel? _paymentChannel;

  static const String PAYMENT_API_BASE_URL = 'http://192.168.82.180:3000';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _setupRealtimeSubscription();
    _testServerConnection();
    _animationController.forward();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _paymentChannel?.unsubscribe();
    _animationController.dispose();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    final appointmentId = widget.appointment['id']?.toString();
    if (appointmentId == null) return;

    _paymentChannel =
        supabase
            .channel('payment-$appointmentId')
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
                final newRecord = payload.newRecord;
                if (newRecord['payment_status'] == 'paid') {
                  _handlePaymentCompletion(success: true);
                }
              },
            )
            .subscribe();
  }

  Future<void> _testServerConnection() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('$PAYMENT_API_BASE_URL/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _initializePayment();
      } else {
        setState(() {
          errorMessage = 'Server returned status ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Cannot connect to payment server: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _initializePayment() async {
    try {
      final paymentAmount =
          widget.doctorData['payment_required_amount']?.toString() ?? '100.00';

      final paymentData = {
        'appointment_id': widget.appointment['id'],
        'amount': paymentAmount,
        'currency': 'ETB',
        'email': widget.motherData['email'] ?? 'patient@example.com',
        'first_name':
            widget.motherData['full_name']?.split(' ').first ?? 'Patient',
        'last_name':
            widget.motherData['full_name']?.split(' ').skip(1).join(' ') ?? '',
        'phone_number': widget.doctorData['phone_number'] ?? '0900000000',
      };

      final response = await http
          .post(
            Uri.parse('$PAYMENT_API_BASE_URL/initialize-appointment-payment'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(paymentData),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['checkout_url'] != null) {
          setState(() {
            checkoutUrl = data['checkout_url'];
            txRef = data['tx_ref'];
            isLoading = false;
          });

          _initializeWebView();
          _startPaymentStatusPolling();
        } else {
          setState(() {
            errorMessage = 'Invalid response: missing checkout_url';
            isLoading = false;
          });
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          setState(() {
            errorMessage =
                errorData['error'] ??
                'Failed to initialize payment (${response.statusCode})';
            isLoading = false;
          });
        } catch (e) {
          setState(() {
            errorMessage =
                'Server error: ${response.statusCode} - ${response.body}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  void _initializeWebView() {
    if (checkoutUrl == null) return;

    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                debugPrint('Payment page started loading: $url');
              },
              onPageFinished: (String url) {
                debugPrint('Payment page finished loading: $url');
                _autoFillPaymentForm();
                _checkUrlForCompletion(url);
              },
              onNavigationRequest: (NavigationRequest request) {
                debugPrint('Navigation request: ${request.url}');
                _checkUrlForCompletion(request.url);
                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(checkoutUrl!));
  }

  void _autoFillPaymentForm() {
    final phoneNumber = widget.doctorData['phone_number'] ?? '';
    final email = widget.motherData['email'] ?? '';
    final amount =
        widget.doctorData['payment_required_amount']?.toString() ?? '';

    if (phoneNumber.isNotEmpty || email.isNotEmpty) {
      String jsCode = '''
        function fillPaymentForm() {
          console.log("Auto-filling payment form...");
          
          var phoneSelectors = [
            'input[type="tel"]',
            'input[name*="phone"]',
            'input[name*="mobile"]',
            'input[placeholder*="phone"]',
            'input[placeholder*="mobile"]'
          ];
          
          var emailSelectors = [
            'input[type="email"]',
            'input[name*="email"]',
            'input[placeholder*="email"]'
          ];
          
          var amountSelectors = [
            'input[name*="amount"]',
            'input[placeholder*="amount"]',
            'input[type="number"]'
          ];
          
          function fillField(selectors, value, fieldType) {
            if (!value) return false;
            
            for (let selector of selectors) {
              let fields = document.querySelectorAll(selector);
              for (let field of fields) {
                if (field && !field.value) {
                  console.log("Filling " + fieldType + " field");
                  field.value = value;
                  field.focus();
                  
                  ['input', 'change', 'blur'].forEach(eventType => {
                    field.dispatchEvent(new Event(eventType, { bubbles: true }));
                  });
                  
                  return true;
                }
              }
            }
            return false;
          }
          
          if ("$phoneNumber") {
            fillField(phoneSelectors, "$phoneNumber", "phone");
          }
          
          if ("$email") {
            fillField(emailSelectors, "$email", "email");
          }
          
          if ("$amount") {
            fillField(amountSelectors, "$amount", "amount");
          }
        }
        
        fillPaymentForm();
        setTimeout(fillPaymentForm, 1000);
        setTimeout(fillPaymentForm, 3000);
      ''';

      _webViewController.runJavaScript(jsCode);
    }
  }

  void _checkUrlForCompletion(String url) {
    if (isPaymentComplete) return;

    if (url.contains('payment-complete') ||
        url.contains('success') ||
        url.contains('callback')) {
      _handlePaymentCompletion();
    }
  }

  void _startPaymentStatusPolling() {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (isPaymentComplete || txRef == null) {
        timer.cancel();
        return;
      }

      try {
        final response = await http.get(
          Uri.parse(
            '$PAYMENT_API_BASE_URL/appointment-payment-status/${widget.appointment['id']}',
          ),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final paymentStatus = data['payment_status'];

          if (paymentStatus == 'paid') {
            timer.cancel();
            _handlePaymentCompletion(success: true);
          }
        }
      } catch (e) {
        debugPrint('Error checking payment status: $e');
      }
    });
  }

  void _handlePaymentCompletion({bool success = false}) {
    if (isPaymentComplete) return;

    setState(() => isPaymentComplete = true);
    _statusTimer?.cancel();

    final l10n = AppLocalizations.of(context)!;

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
                  colors:
                      success
                          ? [Colors.green.shade50, Colors.green.shade100]
                          : [Colors.blue.shade50, Colors.blue.shade100],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: success ? Colors.green : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      success ? Icons.check : Icons.hourglass_empty,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    success ? l10n.paymentSuccessful : l10n.paymentCompleted,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    success
                        ? l10n.paymentSuccessMessage
                        : l10n.paymentProcessingMessage,
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
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: success ? Colors.green : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        l10n.okLabel,
                        style: const TextStyle(
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final paymentAmount =
        widget.doctorData['payment_required_amount']?.toString() ?? '100.00';

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
                l10n.appointmentPayment,
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
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Payment info card
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
                                    child: Icon(
                                      Icons.payment,
                                      color: theme.colorScheme.primary,
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
                                          l10n.paymentRequired,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          'Secure payment processing',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Doctor info
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.colorScheme.primary,
                                            theme.colorScheme.primary
                                                .withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                      child: ClipOval(
                                        child:
                                            widget.doctorData['profile_url'] !=
                                                    null
                                                ? Image.network(
                                                  widget
                                                      .doctorData['profile_url'],
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Icon(
                                                        Icons.person,
                                                        color: Colors.white,
                                                        size: 24,
                                                      ),
                                                )
                                                : const Icon(
                                                  Icons.person,
                                                  color: Colors.white,
                                                  size: 24,
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
                                            widget.doctorData['full_name'] ??
                                                'Doctor',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          if (widget.doctorData['speciality'] !=
                                              null)
                                            Text(
                                              widget.doctorData['speciality'],
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '$paymentAmount ETB',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Auto-fill info
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.green.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        l10n.paymentAutoFillMessage,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Error message
                        if (errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(20),
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
                                      'Connection Error',
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
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: _testServerConnection,
                                    icon: const Icon(Icons.refresh, size: 20),
                                    label: Text(l10n.retryLabel),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Loading or WebView
                        Container(
                          height:
                              MediaQuery.of(context).size.height *
                              0.7, // 70% of screen height
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child:
                                isLoading
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    theme.colorScheme.primary,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            l10n.initializingPayment,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : checkoutUrl != null
                                    ? WebViewWidget(
                                      controller: _webViewController,
                                    )
                                    : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 60,
                                            color: Colors.red.shade400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            errorMessage ??
                                                l10n.paymentInitializationFailed,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.red.shade600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action buttons
                        if (!isLoading && checkoutUrl != null)
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final response = await http.get(
                                          Uri.parse(
                                            '$PAYMENT_API_BASE_URL/appointment-payment-status/${widget.appointment['id']}',
                                          ),
                                        );

                                        if (response.statusCode == 200) {
                                          final data = jsonDecode(
                                            response.body,
                                          );
                                          if (data['payment_status'] ==
                                              'paid') {
                                            _handlePaymentCompletion(
                                              success: true,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l10n.paymentStillPending,
                                                ),
                                                backgroundColor:
                                                    Colors.orange.shade600,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              l10n.errorCheckingPayment,
                                            ),
                                            backgroundColor:
                                                Colors.red.shade600,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.refresh, size: 20),
                                    label: Text(l10n.checkPaymentStatus),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: OutlinedButton.icon(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close, size: 20),
                                    label: Text(l10n.cancelLabel),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red.shade600,
                                      side: BorderSide(
                                        color: Colors.red.shade600,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
