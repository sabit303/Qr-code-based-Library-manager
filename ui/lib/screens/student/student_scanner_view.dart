import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/student_model.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/services/book_service.dart';
import '../../../data/services/borrow_service.dart';
import '../../../data/services/student_service.dart';

class StudentScannerView extends StatefulWidget {
  const StudentScannerView({super.key});

  @override
  State<StudentScannerView> createState() => _StudentScannerViewState();
}

class _StudentScannerViewState extends State<StudentScannerView> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String qrCode) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final user = context.read<AuthProvider>().user!;
      final token = user.token;
      // The QR code now simply contains the book ID
      final book = await BookService(token).getBookById(qrCode);
      // Load the student's own profile to enforce completeness before borrowing.
      final student = await StudentService(token).getStudentById(user.id);

      if (mounted) {
        cameraController.stop();
        if (!student.isProfileComplete) {
          await _showIncompleteProfileDialog(student);
        } else {
          await _showBookDetailsDialog(book, student);
        }
        cameraController.start();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid Book QR or Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showIncompleteProfileDialog(StudentModel student) async {
    final missing = student.missingProfileFields;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Complete Your Profile',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You must complete your profile before you can request books.',
              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Still missing:',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...missing.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text(f,
                            style: GoogleFonts.inter(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 8),
            Text(
              'Go to the Profile tab and tap Edit to update your details.',
              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK',
                style: GoogleFonts.inter(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _showBookDetailsDialog(BookModel book, StudentModel student) async {
    final user = context.read<AuthProvider>().user!;
    bool requesting = false;
    bool alreadyRequestedOrIssued = false;
    DateTime? returnDate;

    // Pre-fetch transactions to disable duplicate requests on the client
    try {
      final requested = await BorrowService(user.token).getTransactions('REQUESTED');
      final issued = await BorrowService(user.token).getTransactions('ISSUED');
      final combined = [...requested, ...issued];
      alreadyRequestedOrIssued = combined.any((t) => t.bookId == book.id && (t.studentId == (user.registration ?? user.id) || t.studentRegistration == user.registration));
    } catch (e) {
      // ignore errors, server will still enforce uniqueness
      alreadyRequestedOrIssued = false;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Book Cover Image
                Center(
                  child: Container(
                    height: 200,
                    width: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: book.coverUrl != null && book.coverUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              book.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Icon(Icons.auto_stories_rounded,
                                      color: Colors.white, size: 48),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(Icons.auto_stories_rounded,
                                  color: Colors.white, size: 48),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Book Found',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${book.author}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildInfoChip('Available', '${book.availableCopies}/${book.totalCopies}'),
                    const SizedBox(width: 12),
                    if (book.category != null)
                      _buildInfoChip('Category', book.category!),
                  ],
                ),
                const SizedBox(height: 24),
                // Return date selector — the student must pick when they will
                // return the book before a request can be submitted.
                Text(
                  'Expected Return Date',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: alreadyRequestedOrIssued
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: returnDate ?? now.add(const Duration(days: 14)),
                            firstDate: now.add(const Duration(days: 1)),
                            lastDate: now.add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setModalState(() => returnDate = picked);
                          }
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: returnDate == null
                            ? AppColors.border
                            : AppColors.primary.withOpacity(0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          returnDate == null
                              ? 'Select a return date'
                              : DateFormat('EEE, MMM d, yyyy').format(returnDate!),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: returnDate == null
                                ? AppColors.textMuted
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down_rounded,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (book.availableCopies > 0 &&
                            !requesting &&
                            !alreadyRequestedOrIssued &&
                            returnDate != null)
                        ? () async {
                            setModalState(() => requesting = true);
                            try {
                              await BorrowService(user.token).requestBook(
                                bookId: book.id,
                                studentReg: user.registration ?? user.id,
                                returnDate: returnDate!,
                              );
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Book request submitted successfully'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            } finally {
                              if (ctx.mounted) {
                                setModalState(() => requesting = false);
                              }
                            }
                          }
                          : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: requesting
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            alreadyRequestedOrIssued
                                ? 'Already Requested / Issued'
                                : book.availableCopies <= 0
                                    ? 'Out of Stock'
                                    : returnDate == null
                                        ? 'Select Return Date'
                                        : 'Request to Borrow',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue!);
                  break; // only process the first one
                }
              }
            },
          ),
          // Scanner Overlay
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      IconButton(
                        onPressed: () => cameraController.toggleTorch(),
                        icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _isProcessing
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : null,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Scan a Book QR Code',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
