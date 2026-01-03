import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/auth_service.dart';

class GuardBuildingVisitorsScreen extends StatefulWidget {
  const GuardBuildingVisitorsScreen({super.key});

  @override
  State<GuardBuildingVisitorsScreen> createState() =>
      _GuardBuildingVisitorsScreenState();
}

class _GuardBuildingVisitorsScreenState
    extends State<GuardBuildingVisitorsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Building Visitors'),
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('building_visitors').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allDocs = snapshot.data?.docs ?? [];

          // Filter active and sort in memory
          final visitors = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isActive'] == true;
          }).toList();

          visitors.sort((a, b) {
            final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime);
          });

          if (visitors.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apartment, size: 100, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'No Building Visitors',
                      style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Add visitors who access multiple apartments',
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
              final data = visitors[index].data() as Map<String, dynamic>;
              return _buildVisitorCard(data);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'ADD VISITOR',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildVisitorCard(Map<String, dynamic> data) {
    final validUntil = (data['validUntil'] as Timestamp).toDate();
    final isExpired = validUntil.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: isExpired ? Colors.grey : Colors.teal,
          child: Icon(Icons.apartment, color: Colors.white, size: 28),
        ),
        title: Text(
          data['visitorName'],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(data['visitorPhone'], style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              data['accessType'] == 'entire_building'
                  ? 'Access: Entire Building'
                  : 'Access: ${(data['apartments'] as List).join(', ')}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Valid Until: ${_formatDate(validUntil)}',
              style: TextStyle(
                fontSize: 14,
                color: isExpired ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
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
                  Future.delayed(Duration.zero, () => _showQRCode(data)),
            ),
            PopupMenuItem(
              child: ListTile(
                leading: Icon(isExpired ? Icons.refresh : Icons.edit),
                title: Text(isExpired ? 'Renew' : 'Extend'),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () =>
                  Future.delayed(Duration.zero, () => _extendValidity(data)),
            ),
            PopupMenuItem(
              child: const ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
              onTap: () => _deleteVisitor(data['id']),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final apartmentsController = TextEditingController();
    String accessType = 'entire_building';
    int validityDays = 30;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Building Visitor'),
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
                  value: accessType,
                  decoration: const InputDecoration(
                    labelText: 'Access Type',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'entire_building',
                      child: Text('Entire Building'),
                    ),
                    DropdownMenuItem(
                      value: 'specific_apartments',
                      child: Text('Specific Apartments'),
                    ),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      accessType = value!;
                    });
                  },
                ),
                if (accessType == 'specific_apartments') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: apartmentsController,
                    decoration: const InputDecoration(
                      labelText: 'Apartments (comma-separated)',
                      hintText: 'e.g., A-101, A-102, B-201',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: validityDays,
                  decoration: const InputDecoration(
                    labelText: 'Validity',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 Days')),
                    DropdownMenuItem(value: 30, child: Text('30 Days')),
                    DropdownMenuItem(value: 90, child: Text('90 Days')),
                    DropdownMenuItem(value: 180, child: Text('6 Months')),
                    DropdownMenuItem(value: 365, child: Text('1 Year')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      validityDays = value!;
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
                await _addVisitor(
                  nameController.text,
                  phoneController.text,
                  accessType,
                  apartmentsController.text,
                  validityDays,
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addVisitor(
    String name,
    String phone,
    String accessType,
    String apartmentsText,
    int validityDays,
  ) async {
    if (name.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly')),
      );
      return;
    }

    try {
      final guardData = await _authService.getResidentData();
      final id = _firestore.collection('building_visitors').doc().id;
      final qrCode = _generateQRCode();

      List<String> apartments = [];
      if (accessType == 'specific_apartments') {
        apartments = apartmentsText
            .split(',')
            .map((a) => a.trim().toUpperCase())
            .where((a) => a.isNotEmpty)
            .toList();
      }

      await _firestore.collection('building_visitors').doc(id).set({
        'id': id,
        'visitorName': name,
        'visitorPhone': phone,
        'accessType': accessType,
        'apartments': apartments,
        'accessCode': qrCode,
        'validFrom': Timestamp.now(),
        'validUntil': Timestamp.fromDate(
          DateTime.now().add(Duration(days: validityDays)),
        ),
        'isActive': true,
        'createdBy': guardData!['residentName'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Building visitor added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _generateQRCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return 'BLD-${List.generate(12, (i) => chars[random.nextInt(chars.length)]).join()}';
  }

  void _showQRCode(Map<String, dynamic> data) {
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
                  'Building Visitor Pass',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                RepaintBoundary(
                  key: qrKey,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal, width: 3),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.apartment,
                              size: 32,
                              color: Colors.teal[700],
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'SafeGate',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'BUILDING VISITOR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal[900],
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        QrImageView(
                          data: data['accessCode'],
                          version: QrVersions.auto,
                          size: 220,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          data['visitorName'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['accessType'] == 'entire_building'
                              ? 'Entire Building Access'
                              : 'Apartments: ${(data['apartments'] as List).join(', ')}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.teal[700],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Valid Until: ${_formatDate((data['validUntil'] as Timestamp).toDate())}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[700],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await _shareQRCode(qrKey, data);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal,
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

  Future<void> _shareQRCode(GlobalKey qrKey, Map<String, dynamic> data) async {
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
        '${tempDir.path}/building_visitor_${data['visitorName']}.png',
      );
      await file.writeAsBytes(pngBytes);

      String message =
          '''
🏢 SafeGate Building Visitor Pass

${data['visitorName']}

${data['accessType'] == 'entire_building' ? 'Access: Entire Building' : 'Apartments: ${(data['apartments'] as List).join(', ')}'}

Show this QR code at the gate.

Valid Until: ${_formatDate((data['validUntil'] as Timestamp).toDate())}
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

  void _extendValidity(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        int days = 30;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Extend Validity'),
            content: DropdownButtonFormField<int>(
              value: days,
              decoration: const InputDecoration(
                labelText: 'Extend By',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 7, child: Text('7 Days')),
                DropdownMenuItem(value: 30, child: Text('30 Days')),
                DropdownMenuItem(value: 90, child: Text('90 Days')),
                DropdownMenuItem(value: 180, child: Text('6 Months')),
              ],
              onChanged: (value) {
                setDialogState(() {
                  days = value!;
                });
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () async {
                  final currentValidUntil = (data['validUntil'] as Timestamp)
                      .toDate();
                  final newValidUntil = currentValidUntil.add(
                    Duration(days: days),
                  );

                  await _firestore
                      .collection('building_visitors')
                      .doc(data['id'])
                      .update({
                        'validUntil': Timestamp.fromDate(newValidUntil),
                      });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Validity extended'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('EXTEND'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteVisitor(String id) async {
    await _firestore.collection('building_visitors').doc(id).update({
      'isActive': false,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visitor deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class Random {
  static Random secure() => Random._();
  Random._();
  int nextInt(int max) => DateTime.now().millisecondsSinceEpoch % max;
}
