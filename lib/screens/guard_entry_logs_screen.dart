import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visitor_model.dart';
import '../utils/date_time_formatter.dart';
import '../services/auth_service.dart';

class GuardEntryLogsScreen extends StatefulWidget {
  const GuardEntryLogsScreen({super.key});

  @override
  State<GuardEntryLogsScreen> createState() => _GuardEntryLogsScreenState();
}

class _GuardEntryLogsScreenState extends State<GuardEntryLogsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String filterType = 'today';
  String? apartmentId;

  @override
  void initState() {
    super.initState();
    _loadApartmentId();
  }

  Future<void> _loadApartmentId() async {
    final guardData = await _authService.getResidentData();
    if (guardData != null && guardData['apartmentName'] != null) {
      setState(() {
        apartmentId = guardData['apartmentName']
            .toString()
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Entry Logs'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, size: 28),
            onSelected: (value) => setState(() => filterType = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'today', child: Text('Today')),
              PopupMenuItem(value: 'yesterday', child: Text('Yesterday')),
              PopupMenuItem(value: 'week', child: Text('Last 7 Days')),
              PopupMenuItem(value: 'month', child: Text('Last 30 Days')),
              PopupMenuItem(value: 'all', child: Text('All Time')),
            ],
          ),
        ],
      ),
      body: apartmentId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('apartments')
                  .doc(apartmentId)
                  .collection('visitors')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var allDocs = snapshot.data?.docs ?? [];

                // Filter visitors who have arrived (have arrival time)
                var arrivedVisitors = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['hasArrived'] == true &&
                      data['arrivalTime'] != null;
                }).toList();

                // Sort by arrival time (most recent first)
                arrivedVisitors.sort((a, b) {
                  final aTime = (a.data() as Map)['arrivalTime'] as Timestamp?;
                  final bTime = (b.data() as Map)['arrivalTime'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

                // Apply time filter based on arrival time
                final now = DateTime.now();
                var visitors = arrivedVisitors.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['arrivalTime'] == null) return false;

                  final arrivalTime = (data['arrivalTime'] as Timestamp)
                      .toDate();

                  switch (filterType) {
                    case 'today':
                      return arrivalTime.year == now.year &&
                          arrivalTime.month == now.month &&
                          arrivalTime.day == now.day;
                    case 'yesterday':
                      final yesterday = now.subtract(const Duration(days: 1));
                      return arrivalTime.year == yesterday.year &&
                          arrivalTime.month == yesterday.month &&
                          arrivalTime.day == yesterday.day;
                    case 'week':
                      final weekAgo = now.subtract(const Duration(days: 7));
                      return arrivalTime.isAfter(weekAgo);
                    case 'month':
                      final monthAgo = now.subtract(const Duration(days: 30));
                      return arrivalTime.isAfter(monthAgo);
                    case 'all':
                    default:
                      return true;
                  }
                }).toList();

                if (visitors.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 100, color: Colors.grey[400]),
                        const SizedBox(height: 20),
                        Text(
                          'No Entry Logs Found',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Change filter or check back later',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(
                            'Total Entries',
                            '${visitors.length}',
                            Icons.history,
                          ),
                          _buildStat(
                            'Departed',
                            '${visitors.where((v) => (v.data() as Map)['departureTime'] != null).length}',
                            Icons.exit_to_app,
                          ),
                          _buildStat(
                            'Still Inside',
                            '${visitors.where((v) => (v.data() as Map)['departureTime'] == null).length}',
                            Icons.location_on,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: visitors.length,
                        itemBuilder: (context, index) {
                          final data =
                              visitors[index].data() as Map<String, dynamic>;
                          final visitor = VisitorModel.fromJson(data);
                          return _buildLogCard(visitor);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.teal[700]),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal[700],
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLogCard(VisitorModel visitor) {
    final hasLeft = visitor.departureTime != null;
    final hasArrived = visitor.hasArrived && visitor.arrivalTime != null;
    Color typeColor = visitor.visitorType == 'guest'
        ? Colors.blue
        : visitor.visitorType == 'delivery'
        ? Colors.orange
        : Colors.green;
    IconData typeIcon = visitor.visitorType == 'guest'
        ? Icons.person
        : visitor.visitorType == 'delivery'
        ? Icons.local_shipping
        : Icons.verified;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: typeColor.withOpacity(0.2),
              child: Icon(typeIcon, color: typeColor, size: 28),
            ),
            if (!hasLeft)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: hasArrived ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          visitor.visitorName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Apartment: ${visitor.apartmentNumber}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            if (hasArrived)
              Text(
                'Entry: ${DateTimeFormatter.formatDateTime(visitor.arrivalTime!)}',
                style: const TextStyle(fontSize: 14, color: Colors.green),
              )
            else
              Text(
                'Approved: ${DateTimeFormatter.formatDateTime(visitor.createdAt)}',
                style: const TextStyle(fontSize: 14, color: Colors.orange),
              ),
            if (hasLeft)
              Text(
                'Exit: ${DateTimeFormatter.formatDateTime(visitor.departureTime!)}',
                style: const TextStyle(fontSize: 14, color: Colors.red),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Phone', visitor.visitorPhone),
                const Divider(height: 16),
                _buildDetailRow(
                  'Type',
                  visitor.visitorType == 'guest'
                      ? 'Guest'
                      : visitor.visitorType == 'delivery'
                      ? 'Delivery'
                      : 'Frequent',
                ),
                const Divider(height: 16),
                _buildDetailRow(
                  'Entry',
                  hasArrived
                      ? DateTimeFormatter.formatDateTime(visitor.arrivalTime!)
                      : 'Not yet arrived',
                ),
                if (visitor.vehiclePlateNumber != null &&
                    visitor.vehiclePlateNumber!.isNotEmpty) ...[
                  const Divider(height: 16),
                  _buildDetailRow('Vehicle', visitor.vehiclePlateNumber!),
                ],
                if (hasLeft) ...[
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Exit',
                    DateTimeFormatter.formatDateTime(visitor.departureTime!),
                  ),
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Duration',
                    DateTimeFormatter.formatDuration(
                      visitor.arrivalTime!,
                      visitor.departureTime!,
                    ),
                  ),
                ],
                if (!hasLeft)
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: hasArrived ? Colors.green : Colors.orange,
                        size: 12,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasArrived ? 'Currently Inside' : 'Expected to Arrive',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasArrived ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
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
}
