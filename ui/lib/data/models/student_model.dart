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
}
