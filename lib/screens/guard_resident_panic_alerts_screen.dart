import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../utils/date_time_formatter.dart';

class GuardResidentPanicAlertsScreen extends StatefulWidget {
  const GuardResidentPanicAlertsScreen({super.key});

  @override
  State<GuardResidentPanicAlertsScreen> createState() =>
      _GuardResidentPanicAlertsScreenState();
}

class _GuardResidentPanicAlertsScreenState
    extends State<GuardResidentPanicAlertsScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  Map<String, dynamic>? guardData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuardData();
  }

  Future<void> _loadGuardData() async {
    final data = await _authService.getResidentData();
    setState(() {
      guardData = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (guardData == null || guardData!['apartmentName'] == null) {
      return const Scaffold(
        body: Center(child: Text('Error loading guard data')),
      );
    }

    String apartmentId = guardData!['apartmentName']
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Emergency Alerts'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('apartments')
            .doc(apartmentId)
            .collection('resident_panic_alerts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data!.docs;

          if (alerts.isEmpty) {
            return _buildEmptyState();
          }

          return _buildAlertsList(alerts);
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade400),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Alerts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Error: $error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'No Resident Alerts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Emergency alerts from residents\nwill appear here when triggered',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(List<QueryDocumentSnapshot> alerts) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final doc = alerts[index];
        final alert = doc.data() as Map<String, dynamic>;

        return _buildAlertCard(doc.id, alert);
      },
    );
  }

  Widget _buildAlertCard(String alertId, Map<String, dynamic> alert) {
    final bool isActive = alert['status'] == 'active';
    final Color themeColor = isActive ? Colors.orange : Colors.grey;

    return Card(
      elevation: isActive ? 6 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isActive ? Colors.orange.shade300 : Colors.grey.shade400,
          width: isActive ? 3 : 2,
        ),
      ),
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emergency,
                    color: themeColor.withOpacity(0.7),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RESIDENT EMERGENCY',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${alert['residentName'] ?? 'Unknown Resident'} • Apt ${alert['apartmentNumber'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? Colors.orange.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'ACKNOWLEDGED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.orange.withOpacity(0.7)
                          : Colors.green.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Timestamp
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  DateTimeFormatter.formatDateTime(
                    (alert['timestamp'] as Timestamp?)!.toDate(),
                  ),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Message (if provided)
            if (alert['message'] != null &&
                alert['message'].toString().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  alert['message'],
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Default message if no custom message
            if (alert['message'] == null ||
                alert['message'].toString().isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: themeColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Resident has triggered an emergency alert and requires immediate assistance',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.4,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (alert['acknowledgedAt'] != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Acknowledged at: ${DateTimeFormatter.formatDateTime((alert['acknowledgedAt'] as Timestamp).toDate())}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Action button
            if (isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _acknowledgeAlert(alertId),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Acknowledge & Respond'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _acknowledgeAlert(String alertId) async {
    try {
      if (guardData == null || guardData!['apartmentName'] == null) return;

      String apartmentId = guardData!['apartmentName']
          .toString()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '');

      await FirebaseFirestore.instance
          .collection('apartments')
          .doc(apartmentId)
          .collection('resident_panic_alerts')
          .doc(alertId)
          .update({
            'status': 'acknowledged',
            'acknowledgedAt': FieldValue.serverTimestamp(),
            'acknowledgedBy': guardData!['uid'],
            'acknowledgedByName': guardData!['residentName'],
          });

      // Stop panic notifications when resident emergency is acknowledged
      await _notificationService.stopPanicNotifications();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Resident emergency acknowledged successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to acknowledge alert: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
