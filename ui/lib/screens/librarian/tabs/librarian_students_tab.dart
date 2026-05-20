import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/student_provider.dart';
import '../../../data/models/student_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/services/borrow_service.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/image_preview_dialog.dart';
import '../librarian_student_scanner_view.dart';
import '../librarian_student_detail_screen.dart';

class LibrarianStudentsTab extends StatefulWidget {
  const LibrarianStudentsTab({super.key});

  @override
  State<LibrarianStudentsTab> createState() => _LibrarianStudentsTabState();
}

class _LibrarianStudentsTabState extends State<LibrarianStudentsTab> {
  final _searchCtrl = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = true}) async {
    final user = context.read<AuthProvider>().user!;
    await context.read<StudentProvider>().fetchStudents(user.token, refresh: refresh);
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;
    final isLoading = context.watch<StudentProvider>().isLoading;
    
    final totalPages = (students.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, students.length);
    final paginatedStudents = students.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('Manage Students',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _openForm(null),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.secondaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SearchBarWidget(
              hint: 'Search students...',
              controller: _searchCtrl,
              onChanged: (q) {
                context.read<StudentProvider>().setSearch(q);
                _currentPage = 1;
                _load();
              },
            ),
          ),
          Expanded(
            child: isLoading && students.isEmpty
                ? _loadingList()
                : students.isEmpty
                    ? _empty()
                    : RefreshIndicator(
                        onRefresh: () { _currentPage = 1; return _load(); },
                        color: AppColors.secondary,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: paginatedStudents.length,
                          itemBuilder: (_, i) => _studentTile(paginatedStudents[i], i),
                        ),
                      ),
          ),
          if (students.isNotEmpty && totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                    icon: const Icon(Icons.chevron_left),
                    color: _currentPage > 1 ? AppColors.secondary : AppColors.textMuted,
                  ),
                  Text(
                    'Page $_currentPage of $totalPages',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  IconButton(
                    onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                    icon: const Icon(Icons.chevron_right),
                    color: _currentPage < totalPages ? AppColors.secondary : AppColors.textMuted,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LibrarianStudentScannerView()));
        },
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
      ),
    );
  }

  Widget _studentTile(StudentModel s, int index) {
    final colors = [AppColors.primary, AppColors.secondary, AppColors.accent, AppColors.gold];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          final user = context.read<AuthProvider>().user!;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LibrarianStudentDetailScreen(
                student: s,
                token: user.token,
              ),
            ),
          );
        },
        leading: s.photoUrl != null && s.photoUrl!.isNotEmpty
            ? GestureDetector(
                onTap: () => showImagePreview(context, s.photoUrl!),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(s.photoUrl!),
                  onBackgroundImageError: (exception, stackTrace) {},
                  child: Container(),
                ),
              )
            : CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.15),
              child: Text(s.initials,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
            ),
        title: Text(s.name,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${s.department} • ${s.session}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(children: [
            StatusBadge(label: 'Roll: ${s.roll}', color: AppColors.primary),
            const SizedBox(width: 6),
            if (s.qrCode != null)
              StatusBadge(label: 'QR ✓', color: AppColors.success)
            else
              StatusBadge(label: 'No QR', color: AppColors.warning),
          ]),
        ]),
        trailing: PopupMenuButton<String>(
          color: AppColors.bgCardLight,
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          onSelected: (val) {
            if (val == 'edit') _openForm(s);
            if (val == 'delete') _confirmDelete(s);
            if (val == 'qr') _genQr(s);
            if (val == 'viewqr') _showQrCode(s);
            if (val == 'history') _openHistory(s);
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit',
              child: Row(children: [
                const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Text('Edit', style: GoogleFonts.inter(color: Colors.white)),
              ])),
            PopupMenuItem(value: 'qr',
              child: Row(children: [
                const Icon(Icons.qr_code_2_rounded, color: AppColors.secondary, size: 18),
                const SizedBox(width: 10),
                Text('Generate QR', style: GoogleFonts.inter(color: Colors.white)),
              ])),
            if (s.qrCode != null && s.qrCode!.isNotEmpty)
              PopupMenuItem(value: 'viewqr',
                child: Row(children: [
                  const Icon(Icons.qr_code_rounded, color: AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  Text('View QR', style: GoogleFonts.inter(color: Colors.white)),
                ])),
            PopupMenuItem(value: 'history',
              child: Row(children: [
                const Icon(Icons.history_rounded, color: AppColors.accent, size: 18),
                const SizedBox(width: 10),
                Text('Books & History', style: GoogleFonts.inter(color: Colors.white)),
              ])),
            PopupMenuItem(value: 'delete',
              child: Row(children: [
                const Icon(Icons.delete_rounded, color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Text('Delete', style: GoogleFonts.inter(color: AppColors.error)),
              ])),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: index * 50)).fadeIn().slideX(begin: 0.1);
  }

  void _openForm(StudentModel? s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StudentFormSheet(
        student: s,
        onSave: (data) async {
          final user = context.read<AuthProvider>().user!;
          if (s == null) {
            await context.read<StudentProvider>().createStudent(user.token, data);
          } else {
            await context.read<StudentProvider>().updateStudent(user.token, s.id, data);
          }
        },
      ),
    );
  }

  Future<void> _genQr(StudentModel s) async {
    final user = context.read<AuthProvider>().user!;
    try {
      final qrUrl = await context.read<StudentProvider>().generateQrCode(user.token, s.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR generated successfully'), backgroundColor: AppColors.success));
        _showQrCode(s);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error));
    }
  }

  void _showQrCode(StudentModel s) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Student QR Code',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.qrCode != null && s.qrCode!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      s.qrCode!,
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                        Container(
                          width: 250,
                          height: 250,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.error, color: Colors.red, size: 48),
                          ),
                        ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const SizedBox(
                    width: 250,
                    height: 250,
                    child: Center(
                      child: Text('No QR Code Generated'),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(s.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              Text('Reg: ${s.registration}',
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 10),
              Text('Librarian can scan this QR to view student details and history',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _openHistory(StudentModel student) async {
    final user = context.read<AuthProvider>().user!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _StudentHistorySheet(
        student: student,
        token: user.token,
      ),
    );
  }

  Future<void> _confirmDelete(StudentModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Student', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Delete "${s.name}"?', style: GoogleFonts.inter(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        final user = context.read<AuthProvider>().user!;
        await context.read<StudentProvider>().deleteStudent(user.token, s.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student deleted'), backgroundColor: AppColors.success));
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
  }

  Widget _loadingList() => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12), height: 80,
          decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16)),
        ),
      );

  Widget _empty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.people_outline, size: 72, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No students yet', style: GoogleFonts.inter(fontSize: 18, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _openForm(null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(gradient: AppColors.secondaryGradient, borderRadius: BorderRadius.circular(12)),
              child: Text('Add First Student', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ]),
      );
}

class _StudentHistorySheet extends StatefulWidget {
  final StudentModel student;
  final String token;

  const _StudentHistorySheet({required this.student, required this.token});

  @override
  State<_StudentHistorySheet> createState() => _StudentHistorySheetState();
}

class _StudentHistorySheetState extends State<_StudentHistorySheet> {
  bool _loading = true;
  String? _error;
  List<TransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _studentKey => widget.student.registration.isNotEmpty
      ? widget.student.registration
      : widget.student.id;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = BorrowService(widget.token);
      final results = await Future.wait([
        service.getTransactions('ISSUED'),
        service.getTransactions('OVERDUE'),
        service.getTransactions('RETURNED'),
        service.getTransactions('REQUESTED'),
      ]);

      final all = results.expand((items) => items).toList();
      final filtered = all.where((t) => t.studentId == _studentKey || t.studentName == widget.student.name).toList();

      if (mounted) {
        setState(() {
          _transactions = filtered;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _transactions.where((t) => t.isIssued || t.isOverdue).toList();
    final history = _transactions;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 16),
              Text(
                widget.student.name,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.student.department} • ${widget.student.registration}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _statCard('Held Now', active.length.toString(), AppColors.success)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Total Records', history.length.toString(), AppColors.accent)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: GoogleFonts.inter(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView(
                            controller: scrollController,
                            children: [
                              _sectionHeader('Currently Held Books'),
                              const SizedBox(height: 12),
                              if (active.isEmpty)
                                _emptyState('No active books for this student')
                              else
                                ...active.map((t) => _transactionCard(t, activeLoan: true)),
                              const SizedBox(height: 24),
                              _sectionHeader('Book History'),
                              const SizedBox(height: 12),
                              if (history.isEmpty)
                                _emptyState('No history found')
                              else
                                ...history.map((t) => _transactionCard(t)),
                            ],
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _transactionCard(TransactionModel t, {bool activeLoan = false}) {
    final statusColor = t.isOverdue
        ? AppColors.error
        : t.isReturned
            ? AppColors.success
            : t.isRequested
                ? AppColors.gold
                : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.bookTitle ?? 'Unknown Book',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (t.bookAuthor != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        t.bookAuthor!,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  t.statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _miniInfo('Borrowed', DateFormat('MMM d, yyyy').format(t.borrowDate)),
              _miniInfo('Due', DateFormat('MMM d, yyyy').format(t.dueDate)),
              if (t.returnDate != null) _miniInfo('Returned', DateFormat('MMM d, yyyy').format(t.returnDate!)),
            ],
          ),
          if (activeLoan && t.isOverdue) ...[
            const SizedBox(height: 12),
            Text(
              'Overdue by ${t.daysOverdue} day${t.daysOverdue != 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Student Form Sheet ────────────────────────────────────────────────────────
class _StudentFormSheet extends StatefulWidget {
  final StudentModel? student;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const _StudentFormSheet({this.student, required this.onSave});

  @override
  State<_StudentFormSheet> createState() => _StudentFormSheetState();
}

class _StudentFormSheetState extends State<_StudentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  late final _nameC = TextEditingController(text: widget.student?.name ?? '');
  late final _rollC = TextEditingController(text: widget.student?.roll ?? '');
  late final _regC = TextEditingController(text: widget.student?.registration ?? '');
  late final _deptC = TextEditingController(text: widget.student?.department ?? '');
  late final _sessC = TextEditingController(text: widget.student?.session ?? '');
  late final _emailC = TextEditingController(text: widget.student?.email ?? '');
  final _passwordC = TextEditingController();
  late final _phoneC = TextEditingController(text: widget.student?.contactNumber ?? '');
  late final _addrC = TextEditingController(text: widget.student?.address ?? '');
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_nameC, _rollC, _regC, _deptC, _sessC, _emailC, _passwordC, _phoneC, _addrC]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'Name': _nameC.text.trim(),
        'Roll': _rollC.text.trim(),
        'Registration': _regC.text.trim(),
        'Department': _deptC.text.trim(),
        'Session': _sessC.text.trim(),
        'Email': _emailC.text.trim(),
        if (widget.student == null || _passwordC.text.isNotEmpty)
          'Password': _passwordC.text,
        'ContactNumber': _phoneC.text.trim(),
        'Address': _addrC.text.trim(),
      };
      
      // Add photo if selected
      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        final base64data = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        data['photoBase64'] = base64data;
      }
      
      await widget.onSave(data);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.error,
      ));
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _pickImage() async {
    final source = kIsWeb ? ImageSource.gallery : ImageSource.camera;
    final img = await _picker.pickImage(source: source, maxWidth: 1200);
    if (img != null) setState(() => _image = img);
  }

  Widget _f(TextEditingController c, String label, IconData icon, {bool req = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        ),
        validator: req ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
      ),
    );
  }

  Widget _passwordField() {
    final isCreate = widget.student == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _passwordC,
        style: const TextStyle(color: Colors.white),
        obscureText: true,
        decoration: const InputDecoration(
          labelText: 'Password *',
          prefixIcon: Icon(Icons.lock_rounded, color: AppColors.textSecondary, size: 20),
        ),
        validator: isCreate
            ? (v) => (v == null || v.isEmpty) ? 'Required' : null
            : null,
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(widget.student != null ? 'Edit Student' : 'Add New Student',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 20),
            _f(_nameC, 'Full Name *', Icons.person_rounded, req: true),
            _f(_rollC, 'Roll Number *', Icons.badge_rounded, req: true),
            _f(_regC, 'Registration *', Icons.app_registration_rounded, req: true),
            _f(_deptC, 'Department *', Icons.school_rounded, req: true),
            _f(_sessC, 'Session *', Icons.date_range_rounded, req: true),
            _f(_emailC, 'Email *', Icons.email_rounded, req: true),
            _passwordField(),
            _f(_phoneC, 'Contact Number *', Icons.phone_rounded, req: true),
            _f(_addrC, 'Address *', Icons.location_on_rounded, req: true),
            const SizedBox(height: 16),
            // Photo Picker Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A3550)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student Photo', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
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
                        return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(kIsWeb ? Icons.image_rounded : Icons.camera_alt_rounded, size: 18),
                    label: Text(_image != null ? 'Change Photo' : (kIsWeb ? 'Select Photo' : 'Take Photo')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary.withOpacity(0.2),
                      foregroundColor: AppColors.secondary,
                      minimumSize: const Size(double.infinity, 36),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GradientButton(
              label: widget.student != null ? 'Update Student' : 'Add Student',
              onTap: _save,
              gradient: AppColors.secondaryGradient,
              icon: widget.student != null ? Icons.save_rounded : Icons.person_add_rounded,
              isLoading: _saving,
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
