import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';
import '../services/visitor_service.dart';
import '../models/visitor_model.dart';

class FrequentVisitorsScreen extends StatefulWidget {
  const FrequentVisitorsScreen({super.key});

  @override
  State<FrequentVisitorsScreen> createState() => _FrequentVisitorsScreenState();
}

class _FrequentVisitorsScreenState extends State<FrequentVisitorsScreen> {
  final AuthService _authService = AuthService();
  final VisitorService _visitorService = VisitorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Frequent Visitors'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<List<VisitorModel>>(
        stream: _visitorService.getFrequentVisitors(
          _authService.currentUser!.uid,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final visitors = snapshot.data ?? [];

          if (visitors.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 100,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No Frequent Visitors',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Add people who visit regularly like maid, milk delivery, etc.',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVisitorDialog,
        icon: const Icon(Icons.person_add, size: 28),
        label: const Text(
          'ADD VISITOR',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildVisitorCard(VisitorModel visitor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: visitor.isActive ? Colors.green : Colors.grey,
          child: Text(
            visitor.visitorName[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          visitor.visitorName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(visitor.visitorPhone, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  visitor.isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: visitor.isActive ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  visitor.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 14,
                    color: visitor.isActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, size: 28),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('View QR Code'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () =>
                  Future.delayed(Duration.zero, () => _showQRCode(visitor)),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(
                  visitor.isActive ? Icons.pause : Icons.play_arrow,
                ),
                title: Text(visitor.isActive ? 'Deactivate' : 'Activate'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _toggleVisitor(visitor),
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _deleteVisitor(visitor),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVisitorDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'Maid';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Frequent Visitor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                        'Maid',
                        'Cook',
                        'Milk Delivery',
                        'Newspaper',
                        'Gardener',
                        'Driver',
                        'Tutor',
                        'Caretaker',
                        'Other',
                      ].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();

                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                Navigator.pop(context);

                final residentData = await _authService.getResidentData();
                String apartmentId = residentData!['apartmentName']
                    .toString()
                    .toLowerCase()
                    .replaceAll(RegExp(r'\s+'), '');
                final result = await _visitorService.createFrequentVisitor(
                  apartmentId: apartmentId,
                  residentId: residentData['uid'],
                  residentName: residentData['residentName'],
                  apartmentNumber: residentData['apartmentNumber'],
                  visitorName: name,
                  visitorPhone: phone,
                  visitorRole: selectedRole,
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
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode(VisitorModel visitor) {
    final GlobalKey qrKey = GlobalKey();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Frequent Visitor Pass',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Enhanced QR Code with branding
                RepaintBoundary(
                  key: qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green, width: 3),
                    ),
                    child: Column(
                      children: [
                        // App branding
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.security,
                              size: 32,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'SafeGate',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'FREQUENT VISITOR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // QR Code
                        QrImageView(
                          data: visitor.accessCode,
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                        ),

                        const SizedBox(height: 20),

                        // Visitor details
                        Text(
                          visitor.visitorName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Apartment ${visitor.apartmentNumber}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phone: ${visitor.visitorPhone}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Permanent pass indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'PERMANENT PASS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Access code
                Text(
                  'Access Code: ${visitor.accessCode}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 20),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await _shareQRCode(qrKey, visitor);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareQRCode(GlobalKey qrKey, VisitorModel visitor) async {
    try {
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/frequent_visitor_${visitor.visitorName}.png',
      );
      await file.writeAsBytes(pngBytes);

      String message =
          '''
🏠 SafeGate Frequent Visitor Pass

${visitor.visitorName}
Apartment: ${visitor.apartmentNumber}

This is a permanent pass. Show this QR code at the gate during each visit.

Access Code: ${visitor.accessCode}
''';

      await Share.shareXFiles([XFile(file.path)], text: message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    }
  }

  void _toggleVisitor(VisitorModel visitor) async {
    final result = await _visitorService.toggleFrequentVisitor(
      visitor.id,
      !visitor.isActive,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _deleteVisitor(VisitorModel visitor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visitor?'),
        content: Text(
          'Are you sure you want to delete ${visitor.visitorName}?',
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
              final result = await _visitorService.deleteVisitor(
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
