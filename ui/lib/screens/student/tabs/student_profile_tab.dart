import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_upload_utils.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/student_model.dart';
import '../../../data/services/student_service.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/image_preview_dialog.dart';

class StudentProfileTab extends StatefulWidget {
  const StudentProfileTab({super.key});

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  StudentModel? _student;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStudent());
  }

  Future<void> _loadStudent() async {
    final user = context.read<AuthProvider>().user!;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final student = await StudentService(user.token).getStudentById(user.id);
      if (mounted) {
        setState(() {
          _student = student;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateQr() async {
    final user = context.read<AuthProvider>().user!;
    try {
      await StudentService(user.token).generateQrCode(user.id);
      await _loadStudent();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _logout() {
    context.read<AuthProvider>().logout();
  }

  Future<void> _editProfile() async {
    final student = _student;
    if (student == null) return;
    final user = context.read<AuthProvider>().user!;

    final updated = await showModalBottomSheet<StudentModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _StudentSelfEditSheet(
        student: student,
        onSave: (data) => StudentService(user.token).updateStudent(user.id, data),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _student = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('My Profile',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        actions: [
          if (_student != null)
            IconButton(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
              tooltip: 'Edit Profile',
            ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _completeProfilePrompt() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Complete your profile',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  'You must fill in all your details and add a photo before you can request books.',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _editProfile,
            child: Text('Update',
                style: GoogleFonts.inter(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final student = _student!;
    final hasQr = student.qrCode != null && student.qrCode!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          if (!student.isProfileComplete) _completeProfilePrompt(),
          // Hero Profile Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.studentGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    student.photoUrl != null && student.photoUrl!.isNotEmpty
                        ? GestureDetector(
                            onTap: () => showImagePreview(context, student.photoUrl!),
                            child: CircleAvatar(
                              radius: 45,
                              backgroundImage: NetworkImage(student.photoUrl!),
                              onBackgroundImageError: (exception, stackTrace) {},
                            ),
                          )
                        : CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              student.initials,
                              style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(student.name,
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    student.department,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 32),

          // Academic Details Section
          _sectionTitle('Academic Details'),
          const SizedBox(height: 12),
          _buildInfoGrid([
            _infoItem('Roll Number', student.roll, Icons.badge_rounded),
            _infoItem('Registration', student.registration, Icons.app_registration_rounded),
            _infoItem('Session', student.session, Icons.calendar_today_rounded),
          ]),

          const SizedBox(height: 32),

          // Contact Details Section
          _sectionTitle('Contact Information'),
          const SizedBox(height: 12),
          _infoCard('Address', student.address ?? 'Not provided', Icons.location_on_rounded),
          const SizedBox(height: 12),
          _infoCard('Contact', student.contactNumber ?? 'Not provided', Icons.phone_android_rounded),

          const SizedBox(height: 32),

          // QR Code Section
          _sectionTitle('Digital Library ID'),
          const SizedBox(height: 16),
          if (hasQr)
            _buildQrSection(student.qrCode!)
          else
            _buildEmptyQrSection(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Text(title,
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        const Spacer(),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accent),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection(String qrData) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 180,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Scan to Borrow',
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'This QR identifies you at the library',
            style: GoogleFonts.inter(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildEmptyQrSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No Digital ID',
              style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _generateQr,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Generate QR Code'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(_error ?? 'Failed to load profile',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: _loadStudent,
            child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Student Self Edit Sheet ───────────────────────────────────────────────────
// Lets a student update their own details. Roll and Registration are shown as
// read-only because they are identity keys managed by the librarian.
class _StudentSelfEditSheet extends StatefulWidget {
  final StudentModel student;
  final Future<StudentModel> Function(Map<String, dynamic>) onSave;

  const _StudentSelfEditSheet({required this.student, required this.onSave});

  @override
  State<_StudentSelfEditSheet> createState() => _StudentSelfEditSheetState();
}

class _StudentSelfEditSheetState extends State<_StudentSelfEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  late final _nameC = TextEditingController(text: widget.student.name);
  late final _deptC = TextEditingController(text: widget.student.department);
  late final _sessC = TextEditingController(text: widget.student.session);
  late final _emailC = TextEditingController(text: widget.student.email ?? '');
  late final _phoneC = TextEditingController(text: widget.student.contactNumber ?? '');
  late final _addrC = TextEditingController(text: widget.student.address ?? '');
  final _passwordC = TextEditingController();
  bool _saving = false;

  List<TextEditingController> get _requiredControllers =>
      [_nameC, _deptC, _sessC, _emailC, _phoneC, _addrC];

  /// A photo is present if the student already has one or has just picked one.
  bool get _hasPhoto =>
      _image != null ||
      (widget.student.photoUrl != null && widget.student.photoUrl!.isNotEmpty);

  /// The Save button is only enabled once every required detail is filled in
  /// and a profile photo exists.
  bool get _isComplete =>
      _requiredControllers.every((c) => c.text.trim().isNotEmpty) && _hasPhoto;

  @override
  void initState() {
    super.initState();
    // Rebuild whenever a required field changes so the Save button and the
    // completeness banner stay in sync.
    for (final c in _requiredControllers) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_nameC, _deptC, _sessC, _emailC, _phoneC, _addrC, _passwordC]) {
      c.removeListener(_onFieldChanged);
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = kIsWeb ? ImageSource.gallery : ImageSource.camera;
    final img = await _picker.pickImage(
      source: source,
      maxWidth: ImageUploadUtils.maxImageDimension,
      maxHeight: ImageUploadUtils.maxImageDimension,
      imageQuality: ImageUploadUtils.imageQuality,
    );
    if (img != null) setState(() => _image = img);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasPhoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a profile photo to complete your profile'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'Name': _nameC.text.trim(),
        'Department': _deptC.text.trim(),
        'Session': _sessC.text.trim(),
        'Email': _emailC.text.trim(),
        'ContactNumber': _phoneC.text.trim(),
        'Address': _addrC.text.trim(),
        if (_passwordC.text.isNotEmpty) 'Password': _passwordC.text,
      };

      if (_image != null) {
        data['photoBase64'] = await ImageUploadUtils.toDataUrl(_image!);
      }

      final updated = await widget.onSave(data);
      if (mounted) Navigator.pop(context, updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _f(TextEditingController c, String label, IconData icon,
      {bool req = false, TextInputType? keyboard, bool obscure = false, String? helper}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        keyboardType: keyboard,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        validator: req ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      ),
    );
  }

  Widget _readOnly(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        enabled: false,
        style: const TextStyle(color: AppColors.textSecondary),
        decoration: InputDecoration(
          labelText: label,
          helperText: 'Managed by the librarian',
          helperStyle: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        ),
      ),
    );
  }

  Widget _incompleteBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete every field and add a photo to unlock book requests at the library.',
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Edit My Profile',
                  style: GoogleFonts.inter(
                      fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 20),
              if (!_isComplete) _incompleteBanner(),
              _readOnly('Roll Number', widget.student.roll, Icons.badge_rounded),
              _readOnly('Registration', widget.student.registration,
                  Icons.app_registration_rounded),
              _f(_nameC, 'Full Name *', Icons.person_rounded, req: true),
              _f(_deptC, 'Department *', Icons.school_rounded, req: true),
              _f(_sessC, 'Session *', Icons.date_range_rounded, req: true),
              _f(_emailC, 'Email *', Icons.email_rounded,
                  req: true, keyboard: TextInputType.emailAddress),
              _f(_phoneC, 'Contact Number *', Icons.phone_rounded,
                  req: true, keyboard: TextInputType.phone),
              _f(_addrC, 'Address *', Icons.location_on_rounded, req: true),
              _f(_passwordC, 'New Password', Icons.lock_rounded,
                  obscure: true, helper: 'Leave blank to keep your current password.'),
              const SizedBox(height: 16),
              // Photo picker
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Profile Photo',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    if (_image != null) ...[
                      FutureBuilder<Uint8List>(
                        future: _image!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                snapshot.data!,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return const SizedBox(
                              height: 120,
                              child: Center(child: CircularProgressIndicator()));
                        },
                      ),
                      const SizedBox(height: 8),
                    ] else if (widget.student.photoUrl != null &&
                        widget.student.photoUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.student.photoUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(kIsWeb ? Icons.image_rounded : Icons.camera_alt_rounded,
                          size: 18),
                      label: Text(_image != null
                          ? 'Change Photo'
                          : (kIsWeb ? 'Select Photo' : 'Take Photo')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 36),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GradientButton(
                label: 'Save Changes',
                onTap: _isComplete ? _save : null,
                gradient: AppColors.primaryGradient,
                icon: Icons.save_rounded,
                isLoading: _saving,
              ),
              if (!_isComplete) ...[
                const SizedBox(height: 8),
                Text(
                  'Fill in all fields and add a photo to enable saving.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
