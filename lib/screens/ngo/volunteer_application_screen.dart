import 'dart:typed_data';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;

class VolunteerApplicantsScreen extends StatefulWidget {
  final String eventId;

  const VolunteerApplicantsScreen({super.key, required this.eventId});

  @override
  State<VolunteerApplicantsScreen> createState() =>
      _VolunteerApplicantsScreenState();
}

class _VolunteerApplicantsScreenState
    extends State<VolunteerApplicantsScreen> {
  @override
  Widget build(BuildContext context) {
    final applicationsRef =
        FirebaseFirestore.instance.collection('event_applications');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Volunteer Applicants'),
        backgroundColor: const Color(0xFF43cea2),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: applicationsRef
              .where('eventId', isEqualTo: widget.eventId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Something went wrong',
                    style: TextStyle(color: Colors.white)),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            final apps = snapshot.data!.docs;

            if (apps.isEmpty) {
              return const Center(
                child: Text('No applications yet.',
                    style: TextStyle(color: Colors.white)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final data = apps[index].data() as Map<String, dynamic>;
                final docId = apps[index].id;
                final status = data['status'] ?? 'pending';

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(data['volunteerId'])
                      .get(),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData ||
                        userSnapshot.data?.data() == null) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Card(
                          child: ListTile(title: Text('Volunteer data not found')),
                        ),
                      );
                    }

                    final userData =
                        userSnapshot.data!.data()! as Map<String, dynamic>;
                    final userName =
                        (userData['name'] as String?)?.trim() ?? 'Unnamed Volunteer';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF43cea2),
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Status: ${status.toUpperCase()}'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _handleAction(
                                value, docId, data['volunteerId'], userName, context),
                            itemBuilder: (context) => [
                              if (status != 'approved')
                                const PopupMenuItem(value: 'approve', child: Text('Approve')),
                              if (status != 'rejected')
                                const PopupMenuItem(value: 'reject', child: Text('Reject')),
                              const PopupMenuItem(value: 'assign', child: Text('Assign Role')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete Volunteer')),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleAction(
    String action,
    String docId,
    String userId,
    String userName,
    BuildContext context,
  ) async {
    final appRef =
        FirebaseFirestore.instance.collection('event_applications').doc(docId);
    final eventRef =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);

    try {
      if (action == 'approve') {
        await appRef.update({'status': 'approved'});

        final eventSnapshot = await eventRef.get();
        final eventData = eventSnapshot.data();

        if (eventData == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load event data')),
          );
          return;
        }

        final hoursCompleted = eventData['duration'] ?? 0;
        final eventTitle = eventData['title'] ?? 'Event';

        final pdfBytes =
            await _generateCertificatePdf(userName, eventTitle, hoursCompleted);

        if (kIsWeb) {
          await saveAndOpenPdfWeb(
              pdfBytes, 'certificate_${userId}_${widget.eventId}.pdf');
        } else {
          final localPath =
              await _saveCertificateLocally(pdfBytes, userId, widget.eventId);
          await OpenFile.open(localPath);
        }

        final certRef =
            FirebaseFirestore.instance.collection('certificates').doc();
        await certRef.set({
          'userId': userId,
          'eventId': widget.eventId,
          'eventTitle': eventTitle,
          'issueDate': Timestamp.now(),
          'hoursCompleted': hoursCompleted,
          'localPath': kIsWeb ? null : 'certificate_${userId}_${widget.eventId}.pdf',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Volunteer approved and certificate saved')),
        );
      } else if (action == 'reject') {
        await appRef.update({'status': 'rejected'});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Volunteer rejected')),
        );
      } else if (action == 'assign') {
        final role = await _showAssignDialog(context);
        if (role != null && role.trim().isNotEmpty) {
          await appRef.update({'role': role.trim()});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Role "$role" assigned')),
          );
        }
      } else if (action == 'delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: Text('Are you sure you want to delete volunteer "$userName"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await appRef.delete();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Volunteer "$userName" deleted')),
          );
        }
      }
    } catch (e, stack) {
      print('❌ Exception: $e');
      print(stack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<Uint8List> _generateCertificatePdf(
      String volunteerName, String eventTitle, int hours) async {
    final pdf = pw.Document();

    final bgColor = PdfColor.fromInt(0xFFFCF8F3);
    final borderColor = PdfColor.fromInt(0xFF185a9d);
    final accentColor = PdfColor.fromInt(0xFF43cea2);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: bgColor,
              border: pw.Border.all(color: borderColor, width: 4),
            ),
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text('CERTIFICATE OF PARTICIPATION',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: borderColor,
                    )),
                pw.SizedBox(height: 30),
                pw.Text('This is proudly presented to',
                    style: pw.TextStyle(fontSize: 18, color: PdfColors.black)),
                pw.SizedBox(height: 15),
                pw.Text(volunteerName,
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor,
                    )),
                pw.SizedBox(height: 15),
                pw.Text(
                    'For their invaluable support and volunteer work in the event:',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Text(eventTitle,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: borderColor,
                    )),
                pw.SizedBox(height: 20),
                pw.Text('Duration: $hours hours',
                    style: pw.TextStyle(fontSize: 16)),
                pw.SizedBox(height: 50),
                pw.Text(
                    'Issued on: ${DateTime.now().toLocal().toString().split(' ')[0]}',
                    style: pw.TextStyle(
                        fontSize: 12, fontStyle: pw.FontStyle.italic)),
                pw.Spacer(),
                pw.Divider(color: borderColor),
                pw.Text('Organization Name',
                    style:
                        pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<String> _saveCertificateLocally(
      Uint8List pdfData, String userId, String eventId) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'certificate_${userId}_$eventId.pdf';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(pdfData);
    return filePath;
  }

  Future<String?> _showAssignDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Role'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter role'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> saveAndOpenPdfWeb(Uint8List pdfData, String filename) async {
    final blob = html.Blob([pdfData], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = filename;

    html.document.body!.append(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
