class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isPrimary;
  final bool notifyOnSos;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.isPrimary = false,
    this.notifyOnSos = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'relationship': relationship,
      'is_primary': isPrimary,
      'notify_on_sos': notifyOnSos,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      relationship: json['relationship'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      notifyOnSos: json['notify_on_sos'] as bool? ?? true,
    );
  }

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? isPrimary,
    bool? notifyOnSos,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      notifyOnSos: notifyOnSos ?? this.notifyOnSos,
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String phoneNumber;
  final String medicalNotes;
  final String bloodGroup;
  final List<EmergencyContact> contacts;

  UserProfile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.medicalNotes = 'Visually impaired individual using SafePath Smart Blind Stick.',
    this.bloodGroup = 'O+',
    required this.contacts,
  });

  factory UserProfile.defaultUser() {
    return UserProfile(
      id: 'user-001',
      name: 'Alex Mercer (Stick User)',
      phoneNumber: '+1-555-0199',
      medicalNotes: 'Moderate visual impairment. Uses Smart Blind Stick with ultrasonic hazard alerts.',
      bloodGroup: 'B+',
      contacts: [
        EmergencyContact(
          id: 'c-1',
          name: 'Sarah Mercer (Caregiver / Sister)',
          phoneNumber: '+1-555-0123',
          relationship: 'Sister',
          isPrimary: true,
          notifyOnSos: true,
        ),
        EmergencyContact(
          id: 'c-2',
          name: 'Dr. Robert Davis (Physician)',
          phoneNumber: '+1-555-0144',
          relationship: 'Doctor',
          isPrimary: false,
          notifyOnSos: true,
        ),
        EmergencyContact(
          id: 'c-3',
          name: 'Emergency Dispatch (911 / 112)',
          phoneNumber: '911',
          relationship: 'Emergency Services',
          isPrimary: false,
          notifyOnSos: true,
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'medical_notes': medicalNotes,
      'blood_group': bloodGroup,
      'contacts': contacts.map((c) => c.toJson()).toList(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      medicalNotes: json['medical_notes'] as String? ?? '',
      bloodGroup: json['blood_group'] as String? ?? 'O+',
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((c) => EmergencyContact.fromJson(Map<String, dynamic>.from(c)))
              .toList() ??
          [],
    );
  }

  UserProfile copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? medicalNotes,
    String? bloodGroup,
    List<EmergencyContact>? contacts,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      contacts: contacts ?? this.contacts,
    );
  }
}

class CaregiverProfile {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationshipToUser;
  final String monitoredUserId;

  CaregiverProfile({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationshipToUser,
    required this.monitoredUserId,
  });

  factory CaregiverProfile.defaultCaregiver() {
    return CaregiverProfile(
      id: 'caregiver-001',
      name: 'Sarah Mercer',
      phoneNumber: '+1-555-0123',
      relationshipToUser: 'Sister & Primary Caregiver',
      monitoredUserId: 'user-001',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'relationship': relationshipToUser,
      'monitored_user_id': monitoredUserId,
    };
  }

  factory CaregiverProfile.fromJson(Map<String, dynamic> json) {
    return CaregiverProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      relationshipToUser: json['relationship'] as String,
      monitoredUserId: json['monitored_user_id'] as String,
    );
  }
}
