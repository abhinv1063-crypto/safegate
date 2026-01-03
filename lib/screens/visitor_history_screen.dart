import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';
import '../services/visitor_service.dart';
import '../models/visitor_model.dart';
import '../utils/date_time_formatter.dart';

class VisitorHistoryScreen extends StatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  State<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends State<VisitorHistoryScreen> {
  final AuthService _authService = AuthService();
  final VisitorService _visitorService = VisitorService();
  final ScreenshotController _screenshotController = ScreenshotController();

  String filterType = 'all'; // all, guest, delivery, frequent

  @override
  void initState() {
    super.initState();
    // Check for expiring visitors when screen opens
    _checkExpiringVisitors();
  }

  Future<void> _checkExpiringVisitors() async {
    await _visitorService.checkAndNotifyExpiringVisitors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Visitor History'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, size: 28),
            onSelected: (value) {
              setState(() {
                filterType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Visitors')),
              const PopupMenuItem(value: 'guest', child: Text('Guests Only')),
              const PopupMenuItem(
                value: 'delivery',
                child: Text('Deliveries Only'),
              ),
              const PopupMenuItem(
                value: 'frequent',
                child: Text('Frequent Visitors'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<VisitorModel>>(
        stream: _visitorService.getVisitorHistory(
          _authService.currentUser!.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var visitors = snapshot.data ?? [];

          // Apply filter
          if (filterType != 'all') {
            visitors = visitors
                .where((v) => v.visitorType == filterType)
                .toList();
          }

          if (visitors.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 100, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      filterType == 'all'
                          ? 'No Visitor History'
                          : 'No ${_getFilterTitle(filterType)}',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your visitor history will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: visitors.length,
            itemBuilder: (context, index) {
              final visitor = visitors[index];
              return _buildVisitorCard(visitor);
            },
          );
        },
      ),
    );
  }

  Widget _buildVisitorCard(VisitorModel visitor) {
    // Determine color based on visitor type
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (visitor.visitorType) {
      case 'guest':
        typeColor = Colors.blue;
        typeIcon = Icons.person;
        typeLabel = 'Guest';
        break;
      case 'delivery':
        typeColor = Colors.orange;
        typeIcon = Icons.local_shipping;
        typeLabel = 'Delivery';
        break;
      case 'frequent':
        typeColor = Colors.green;
        typeIcon = Icons.verified;
        typeLabel = 'Frequent';
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.help_outline;
        typeLabel = 'Other';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 28,
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: typeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!visitor.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Expired',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${DateTimeFormatter.formatDateTime(visitor.createdAt)}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Phone', visitor.visitorPhone, Icons.phone),
                const Divider(height: 16),
                _buildDetailRow(
                  'Access Code',
                  visitor.accessCode,
                  Icons.qr_code,
                ),
                const Divider(height: 16),

                // QR Code display for active visitors who haven't departed
                if (visitor.isActive && visitor.departureTime == null) ...[
                  const Text(
                    'QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Screenshot(
                        controller: _screenshotController,
                        child: QrImageView(
                          data: visitor.accessCode,
                          version: QrVersions.auto,
                          size: 200.0,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareQRCode(visitor),
                      icon: const Icon(Icons.share),
                      label: const Text('SHARE QR CODE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const Divider(height: 16),
                ],

                _buildDetailRow(
                  'Valid From',
                  DateTimeFormatter.formatDateTime(visitor.validFrom),
                  Icons.calendar_today,
                ),
                const Divider(height: 16),
                _buildDetailRow(
                  'Valid Until',
                  DateTimeFormatter.formatDateTime(visitor.validUntil),
                  Icons.event,
                ),

                if (visitor.hasArrived) ...[
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Arrival Time',
                    visitor.arrivalTime != null
                        ? DateTimeFormatter.formatDateTime(visitor.arrivalTime!)
                        : 'Not recorded',
                    Icons.login,
                    color: Colors.green,
                  ),
                ],

                if (visitor.departureTime != null) ...[
                  const Divider(height: 16),
                  _buildDetailRow(
                    'Departure Time',
                    DateTimeFormatter.formatDateTime(visitor.departureTime!),
                    Icons.logout,
                    color: Colors.red,
                  ),
                ],

                const Divider(height: 16),
                _buildDetailRow(
                  'Status',
                  visitor.isActive ? 'Active' : 'Inactive',
                  visitor.isActive ? Icons.check_circle : Icons.cancel,
                  color: visitor.isActive ? Colors.green : Colors.grey,
                ),

                // Action buttons
                if (visitor.isActive && visitor.departureTime == null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _changeValidityTime(visitor),
                          icon: const Icon(Icons.schedule),
                          label: const Text('CHANGE VALIDITY'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _markDeparted(visitor),
                          icon: const Icon(Icons.logout),
                          label: const Text('DEPARTED'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else if (visitor.isActive &&
                    visitor.departureTime != null) ...[
                  // For active visitors who haven't departed yet, show change validity option
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _changeValidityTime(visitor),
                      icon: const Icon(Icons.schedule),
                      label: const Text('CHANGE VALIDITY TIME'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _markDeparted(VisitorModel visitor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Departed?'),
        content: Text(
          'Mark ${visitor.visitorName} as departed?\n\nThis will deactivate their access code.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);

              final residentData = await _authService.getResidentData();
              String apartmentId = residentData!['apartmentName']
                  .toString()
                  .toLowerCase()
                  .replaceAll(RegExp(r'\s+'), '');
              final result = await _visitorService.markDeparted(
                apartmentId,
                visitor.id,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success']
                        ? Colors.green
                        : Colors.red,
                  ),
                );
              }
            },
            child: const Text('MARK DEPARTED'),
          ),
        ],
      ),
    );
  }

  void _changeValidityTime(VisitorModel visitor) {
    DateTime selectedValidFrom = visitor.validFrom;
    DateTime selectedValidUntil = visitor.validUntil;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Validity Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select new validity period for this visitor:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              // Valid From
              InkWell(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedValidFrom,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.fromDateTime(selectedValidFrom),
                    );
                    if (pickedTime != null && mounted) {
                      setState(() {
                        selectedValidFrom = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Valid From: ${DateTimeFormatter.formatDateTime(selectedValidFrom)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Valid Until
              InkWell(
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedValidUntil,
                    firstDate: selectedValidFrom,
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    final TimeOfDay? pickedTime = await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.fromDateTime(selectedValidUntil),
                    );
                    if (pickedTime != null && mounted) {
                      setState(() {
                        selectedValidUntil = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Valid Until: ${DateTimeFormatter.formatDateTime(selectedValidUntil)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final residentData = await _authService.getResidentData();
                String apartmentId = residentData!['apartmentName']
                    .toString()
                    .toLowerCase()
                    .replaceAll(RegExp(r'\s+'), '');
                final result = await _visitorService.updateVisitorValidity(
                  apartmentId: apartmentId,
                  visitorId: visitor.id,
                  validFrom: selectedValidFrom,
                  validUntil: selectedValidUntil,
                );

                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: result['success']
                          ? Colors.green
                          : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('UPDATE'),
            ),
          ],
        ),
      ),
    );
  }

  void _shareQRCode(VisitorModel visitor) async {
    try {
      // Capture the QR code as image
      final image = await _screenshotController.capture();

      if (image != null) {
        // Create a temporary file
        final tempDir = await getTemporaryDirectory();
        final file = await File(
          '${tempDir.path}/visitor_qr_${visitor.id}.png',
        ).create();
        await file.writeAsBytes(image);

        // Share the QR code image with visitor details
        final shareText =
            '''
SafeGate Visitor QR Code

Visitor: ${visitor.visitorName}
Phone: ${visitor.visitorPhone}
Valid From: ${DateTimeFormatter.formatDateTime(visitor.validFrom)}
Valid Until: ${DateTimeFormatter.formatDateTime(visitor.validUntil)}
Access Code: ${visitor.accessCode}

Please show this QR code at the gate for entry.
''';

        await Share.shareXFiles(
          [XFile(file.path)],
          text: shareText,
          subject: 'SafeGate Visitor QR Code - ${visitor.visitorName}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share QR code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getFilterTitle(String filter) {
    switch (filter) {
      case 'guest':
        return 'Guests';
      case 'delivery':
        return 'Deliveries';
      case 'frequent':
        return 'Frequent Visitors';
      default:
        return 'Visitors';
    }
  }
}
