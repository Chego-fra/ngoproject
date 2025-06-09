import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:intl/intl.dart';

class EventFormScreen extends StatefulWidget {
  final String? eventId;

  const EventFormScreen({super.key, this.eventId});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxVolunteersController = TextEditingController();
  final _durationController = TextEditingController();

  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _loadEventData();
    }
  }

  Future<void> _loadEventData() async {
    setState(() => _isLoading = true);
    final doc = await FirebaseFirestore.instance.collection('events').doc(widget.eventId!).get();
    final data = doc.data();

    if (data != null) {
      _titleController.text = data['title'] ?? '';
      _descController.text = data['description'] ?? '';
      _locationController.text = data['location'] ?? '';
      _maxVolunteersController.text = '${data['maxVolunteers'] ?? 50}';
      _durationController.text = '${data['duration'] ?? 0}';
      _selectedDate = (data['date'] as Timestamp).toDate();
    }

    setState(() => _isLoading = false);
  }

  Future<void> sendPushMessage(String token, String title, String body) async {
    final serviceAccount = ServiceAccountCredentials.fromJson(
      File('assets/service_account.json').readAsStringSync(), // Make sure this file exists
    );

    const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(serviceAccount, scopes);

    const projectId = 'ngoproject-2458e'; // Update this if your project ID is different

    final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

    final messagePayload = {
      "message": {
        "token": token,
        "notification": {
          "title": title,
          "body": body,
        },
        "android": {
          "priority": "high"
        },
      }
    };

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messagePayload),
    );

    if (response.statusCode == 200) {
      print("✅ Notification sent successfully");
    } else {
      print("❌ Failed to send notification: ${response.statusCode}");
      print("Response: ${response.body}");
    }

    client.close();
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;

    setState(() => _isLoading = true);

    final newEvent = {
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'location': _locationController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate!),
      'maxVolunteers': int.tryParse(_maxVolunteersController.text) ?? 50,
      'duration': int.tryParse(_durationController.text.trim()) ?? 0,
      'organizerId': FirebaseAuth.instance.currentUser!.uid,
    };

    final collection = FirebaseFirestore.instance.collection('events');

    if (widget.eventId == null) {
      final eventRef = await collection.add(newEvent);

      final volunteersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      final title = newEvent['title'];

      for (final doc in volunteersSnapshot.docs) {
        final fcmToken = doc['fcmToken'];
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .collection('notifications')
            .doc();

        batch.set(notifRef, {
          'message': 'New event "$title" has been added. Check it out!',
          'seen': false,
          'timestamp': Timestamp.now(),
          'eventId': eventRef.id,
        });

        if (fcmToken != null && fcmToken.toString().isNotEmpty) {
          await sendPushMessage(
            fcmToken,
            'New Event: $title',
            'An opportunity awaits! Tap to check details.',
          );
        }
      }

      await batch.commit();
    } else {
      await collection.doc(widget.eventId!).update(newEvent);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _maxVolunteersController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventId == null ? 'Create Event' : 'Edit Event'),
        backgroundColor: const Color(0xFF43cea2),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF43cea2), Color(0xFF185a9d)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        controller: _titleController,
                                        decoration: const InputDecoration(labelText: 'Event Title'),
                                        keyboardType: TextInputType.text,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                                        ],
                                        validator: (value) =>
                                            value == null || value.trim().isEmpty ? 'Required' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _descController,
                                        decoration: const InputDecoration(labelText: 'Description'),
                                        maxLines: 3,
                                        validator: (value) =>
                                            value == null || value.isEmpty ? 'Required' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _locationController,
                                        decoration: const InputDecoration(labelText: 'Location'),
                                        validator: (value) =>
                                            value == null || value.isEmpty ? 'Required' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _maxVolunteersController,
                                        decoration: const InputDecoration(labelText: 'Max Volunteers'),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _durationController,
                                        decoration: const InputDecoration(labelText: 'Volunteer Hours (Duration)'),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          final parsed = int.tryParse(value ?? '');
                                          if (parsed == null || parsed <= 0) return 'Enter a valid duration';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      ListTile(
                                        tileColor: Colors.grey[100],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        title: Text(
                                          _selectedDate == null
                                              ? 'Pick event date'
                                              : 'Date: ${DateFormat.yMMMd().format(_selectedDate!)}',
                                        ),
                                        trailing: const Icon(Icons.calendar_today),
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime(2100),
                                          );
                                          if (date != null) {
                                            setState(() => _selectedDate = date);
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: _saveEvent,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF43cea2),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(Icons.save),
                                        label: const Text(
                                          'Save Event',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
