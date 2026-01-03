import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visitor_model.dart';
import '../utils/date_time_formatter.dart';
import '../services/auth_service.dart';

class GuardCurrentVisitorsScreen extends StatefulWidget {
  const GuardCurrentVisitorsScreen({super.key});

  @override
  State<GuardCurrentVisitorsScreen> createState() =>
      _GuardCurrentVisitorsScreenState();
}

class _GuardCurrentVisitorsScreenState
    extends State<GuardCurrentVisitorsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String selectedTab = 'inside'; // inside, requests
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
        title: const Text('Current Status'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    'Inside Building',
                    'inside',
                    Icons.people,
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    'Pending Requests',
                    'requests',
                    Icons.pending_actions,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: selectedTab == 'inside'
          ? _buildInsideVisitors()
          : _buildPendingRequests(),
    );
  }

  Widget _buildTabButton(String label, String value, IconData icon) {
    final isSelected = selectedTab == value;
    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsideVisitors() {
    if (apartmentId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('visitors')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final visitors = snapshot.data?.docs ?? [];

        // Filter out departed visitors
        final activeVisitors = visitors.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['departureTime'] == null;
        }).toList();

        if (activeVisitors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No Active Visitors',
                  style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeVisitors.length,
          itemBuilder: (context, index) {
            final visitorData =
                activeVisitors[index].data() as Map<String, dynamic>;
            final visitor = VisitorModel.fromJson(visitorData);
            return _buildVisitorCard(visitor);
          },
        );
      },
    );
  }

  Widget _buildVisitorCard(VisitorModel visitor) {
    Color typeColor;
    IconData typeIcon;

    switch (visitor.visitorType) {
      case 'guest':
        typeColor = Colors.blue;
        typeIcon = Icons.person;
        break;
      case 'delivery':
        typeColor = Colors.orange;
        typeIcon = Icons.local_shipping;
        break;
      case 'frequent':
        typeColor = Colors.green;
        typeIcon = Icons.verified;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: typeColor.withOpacity(0.2),
          child: Icon(typeIcon, color: typeColor, size: 28),
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
            if (visitor.vehiclePlateNumber != null &&
                visitor.vehiclePlateNumber!.isNotEmpty) ...[
              Text(
                'Vehicle: ${visitor.vehiclePlateNumber}',
                style: const TextStyle(fontSize: 14, color: Colors.blue),
              ),
              const SizedBox(height: 4),
            ],
            if (visitor.hasArrived && visitor.arrivalTime != null)
              Text(
                'Arrived: ${DateTimeFormatter.formatDateTime(visitor.arrivalTime!)}',
                style: const TextStyle(fontSize: 14, color: Colors.green),
              )
            else
              const Text(
                'Expected - Approved',
                style: TextStyle(fontSize: 14, color: Colors.orange),
              ),
          ],
        ),
        trailing: Icon(
          Icons.circle,
          color: visitor.hasArrived ? Colors.green : Colors.orange,
          size: 12,
        ),
      ),
    );
  }

  Widget _buildPendingRequests() {
    if (apartmentId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('apartments')
          .doc(apartmentId)
          .collection('visitor_requests')
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 100, color: Colors.grey[400]),
                const SizedBox(height: 20),
                Text(
                  'No Pending Requests',
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
            final requestData = requests[index].data() as Map<String, dynamic>;
            return _buildRequestCard(requestData);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const CircleAvatar(
          radius: 28,
          backgroundColor: Colors.purple,
          child: Icon(Icons.help_outline, color: Colors.white, size: 28),
        ),
        title: Text(
          request['visitorName'],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pending, size: 14, color: Colors.orange[700]),
                      const SizedBox(width: 4),
                      Text(
                        'PENDING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'To: Apt ${request['apartmentNumber']}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Visitor', request['visitorName']),
                const Divider(height: 16),
                _buildDetailRow('Phone', request['visitorPhone']),
                const Divider(height: 16),
                _buildDetailRow('Apartment', request['apartmentNumber']),
                const Divider(height: 16),
                _buildDetailRow('Resident', request['residentName']),
                if (request['remarks'] != null &&
                    request['remarks'].isNotEmpty) ...[
                  const Divider(height: 16),
                  _buildDetailRow('Remarks', request['remarks']),
                ],
                const Divider(height: 16),
                _buildDetailRow('Requested By', request['guardName']),
                const Divider(height: 16),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Waiting for resident approval...',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
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
