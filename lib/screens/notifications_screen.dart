import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/visitor_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _authService = AuthService();
  final VisitorService _visitorService = VisitorService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? residentData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResidentData();
  }

  Future<void> _loadResidentData() async {
    final data = await _authService.getResidentData();
    setState(() {
      residentData = data;
      isLoading = false;
    });
  }

  Widget build(BuildContext context) {
    if (isLoading || residentData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String apartmentId = residentData!['apartmentName']
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('apartments')
            .doc(apartmentId)
            .collection('visitor_requests')
            .where('residentId', isEqualTo: _authService.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allRequests = snapshot.data?.docs ?? [];

          // Filter pending in memory
          final requests = allRequests.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'pending';
          }).toList();

          // Sort by created date
          requests.sort((a, b) {
            final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No New Notifications',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              return _buildRequestCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_add_alt,
                    color: Colors.purple[700],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Surprise Visitor Request',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data['visitorName'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Details
            _buildDetailRow('Phone', data['visitorPhone'], Icons.phone),
            const SizedBox(height: 12),
            _buildDetailRow('Requested by', data['guardName'], Icons.shield),

            if (data['vehiclePlateNumber'] != null &&
                data['vehiclePlateNumber'].isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Vehicle',
                data['vehiclePlateNumber'],
                Icons.directions_car,
              ),
            ],

            if (data['remarks'] != null && data['remarks'].isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildDetailRow('Remarks', data['remarks'], Icons.note),
            ],

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleRequest(data, false),
                    icon: const Icon(Icons.close),
                    label: const Text(
                      'REJECT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _handleRequest(data, true),
                    icon: const Icon(Icons.check),
                    label: const Text(
                      'APPROVE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRequest(Map<String, dynamic> data, bool approved) async {
    try {
      if (approved) {
        final residentData = await _authService.getResidentData();

        final result = await _visitorService.createGuestInvitation(
          residentId: residentData!['uid'],
          residentName: residentData['residentName'],
          apartmentNumber: residentData['apartmentNumber'],
          apartmentId: residentData['apartmentName']
              .toString()
              .toLowerCase()
              .replaceAll(RegExp(r'\s+'), ''),
          visitorName: data['visitorName'],
          visitorPhone: data['visitorPhone'],
          validFrom: DateTime.now(),
          validUntil: DateTime.now().add(const Duration(hours: 6)),
          vehiclePlateNumber: data['vehiclePlateNumber'],
        );

        if (result['success']) {
          await _firestore
              .collection('visitor_requests')
              .doc(data['id'])
              .update({
                'status': 'approved',
                'approvedAt': FieldValue.serverTimestamp(),
                'visitorId': result['visitor'].id,
              });

          if (mounted) {
            // Show QR code to resident
            _showApprovedQRCode(result['visitor']);
          }
        }
      } else {
        await _firestore.collection('visitor_requests').doc(data['id']).update({
          'status': 'rejected',
          'rejectedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request rejected'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showApprovedQRCode(dynamic visitor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 32),
            const SizedBox(width: 10),
            const Text('Approved!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Visitor has been approved and QR code generated.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'The QR code is now available in your Visitor History.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Access Code: ${visitor.accessCode}',
              style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
