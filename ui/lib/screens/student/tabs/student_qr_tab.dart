import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/models/student_model.dart';
import '../../../data/services/student_service.dart';

class StudentQrTab extends StatefulWidget {
  const StudentQrTab({super.key});

  @override
  State<StudentQrTab> createState() => _StudentQrTabState();
}

class _StudentQrTabState extends State<StudentQrTab> {
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
    setState(() { _isLoading = true; _error = null; });
    try {
      final student = await StudentService(user.token).getStudentById(user.id);
      if (mounted) setState(() { _student = student; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('My QR Code',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final student = _student!;
    final hasQr = student.qrCode != null && student.qrCode!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.studentGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    student.initials,
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name,
                          style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(student.department,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8))),
                      Text('Roll: ${student.roll}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),

          const SizedBox(height: 28),

          // QR Code
          if (hasQr) ...[
            Text(
              'Your Library Card',
              style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Show this QR code to the librarian',
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: QrImageView(
                data: student.qrCode!,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(
                  begin: const Offset(0.8, 0.8),
                ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3550)),
              ),
              child: Text(
                student.qrCode!,
                style: GoogleFonts.sourceCodePro(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ] else ...[
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_2_rounded,
                      size: 80,
                      color: AppColors.primary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No QR Code Yet',
                      style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    'Generate your QR code to use the library',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: _generateQr,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text('Generate QR Code',
                          style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Info cards
          _buildInfoRow('Registration', student.registration),
          _buildInfoRow('Session', student.session),
          if (student.contactNumber != null)
            _buildInfoRow('Contact', student.contactNumber!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
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
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
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
