import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../models/user_profile.dart';
import '../providers/settings_provider.dart';
import '../widgets/contact_card.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  void _showAddContactDialog(BuildContext context, SettingsProvider settings) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    bool isPrimary = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Emergency Contact'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g. Sarah Mercer',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'e.g. +1-555-0123',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: relationController,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      hintText: 'e.g. Sister, Doctor, Caregiver',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Primary Contact'),
                    subtitle: const Text('First caregiver alerted during SOS'),
                    value: isPrimary,
                    onChanged: (val) => setState(() => isPrimary = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final phone = phoneController.text.trim();
                  final relation = relationController.text.trim();

                  if (name.isNotEmpty && phone.isNotEmpty) {
                    final newContact = EmergencyContact(
                      id: const Uuid().v4(),
                      name: name,
                      phoneNumber: phone,
                      relationship: relation.isNotEmpty ? relation : 'Contact',
                      isPrimary: isPrimary,
                    );
                    settings.addEmergencyContact(newContact);
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Add Contact'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final contacts = settings.userProfile.contacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primaryBlue),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'These contacts will receive immediate distress signals with your live GPS location when SOS or fall detection is activated.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: contacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.contact_phone_outlined,
                            size: 64,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No emergency contacts added yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap the button below to add your primary caregiver.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return ContactCard(
                          contact: contact,
                          isManageMode: true,
                          onDelete: () => settings.removeEmergencyContact(contact.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddContactDialog(context, settings),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Contact'),
      ),
    );
  }
}
