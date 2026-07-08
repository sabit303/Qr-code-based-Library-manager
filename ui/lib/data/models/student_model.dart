class StudentModel {
  final String id;
  final String name;
  final String roll;
  final String registration;
  final String department;
  final String session;
  final String? email;
  final String? contactNumber;
  final String? address;
  final String? qrCode;
  final String? photoUrl;
  final DateTime? createdAt;

  StudentModel({
    required this.id,
    required this.name,
    required this.roll,
    required this.registration,
    required this.department,
    required this.session,
    this.email,
    this.contactNumber,
    this.address,
    this.qrCode,
    this.photoUrl,
    this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] ?? '',
      name: json['Name'] ?? json['name'] ?? '',
      roll: json['Roll'] ?? json['roll'] ?? '',
      registration: json['Registration'] ?? json['registration'] ?? '',
      department: json['Department'] ?? json['department'] ?? '',
      session: json['Session'] ?? json['session'] ?? '',
      email: json['Email'] ?? json['email'],
      contactNumber: json['ContactNumber'] ?? json['contactNumber'],
      address: json['Address'] ?? json['address'],
      qrCode: json['qrCode'],
      photoUrl: json['PhotoUrl'] ?? json['photoUrl'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'Name': name,
        'Roll': roll,
        'Registration': registration,
        'Department': department,
        'Session': session,
        if (email != null) 'Email': email,
        if (contactNumber != null) 'ContactNumber': contactNumber,
        if (address != null) 'Address': address,
      };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'S';
  }

  /// A profile is considered complete only when every detail a student is
  /// expected to fill in has a non-empty value (plus a profile photo).
  /// Roll and Registration are always set by the librarian at creation time.
  bool get isProfileComplete {
    bool has(String? v) => v != null && v.trim().isNotEmpty;
    return has(name) &&
        has(roll) &&
        has(registration) &&
        has(department) &&
        has(session) &&
        has(email) &&
        has(contactNumber) &&
        has(address) &&
        has(photoUrl);
  }

  /// Human-readable list of the details still missing from the profile.
  List<String> get missingProfileFields {
    bool has(String? v) => v != null && v.trim().isNotEmpty;
    return [
      if (!has(name)) 'Full Name',
      if (!has(department)) 'Department',
      if (!has(session)) 'Session',
      if (!has(email)) 'Email',
      if (!has(contactNumber)) 'Contact Number',
      if (!has(address)) 'Address',
      if (!has(photoUrl)) 'Profile Photo',
    ];
  }
}
