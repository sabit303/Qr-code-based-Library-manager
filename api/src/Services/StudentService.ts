import { IStudentRepository } from "../Interfaces/IStudentRepository.js";
import { IBorrowRepository } from "../Interfaces/IBorrowRepository.js";
import { CreateStudentDTO, UpdateStudentDTO } from "../DTOs/StudentDTO.js";
import { Student } from "../Entities/Student.js";
import { QRCodeService } from "./QRCodeService.js";
import { PasswordHasher } from "../Helper/passHash.js";
import { ForbiddenError, NotFoundError, ConflictError } from "../errors/AppError.js";

export class StudentService {
  constructor(
    private studentRepository: IStudentRepository,
    private qrCodeService: QRCodeService,
    private passwordHasher: PasswordHasher,
    private borrowRepository?: IBorrowRepository
  ) {}

  
  async create(dto: CreateStudentDTO): Promise<Student> {
    //const qrCode = await this.qrCodeService.generate(dto.Registration);
    // Default the password to the registration number if one wasn't supplied.
    const rawPassword = dto.Password || dto.Registration;
    const hashedPassword = await this.passwordHasher.hashPassword(rawPassword);
    
    return this.studentRepository.create({ 
      ...dto, 
      Password: hashedPassword,
      //qrCode 
    });
  }
  async getAll(params: { page: number; limit: number; }): Promise<{ students: Student[]; total: number; page: number; limit: number }> {
    console.log(params)
    const result = await this.studentRepository.findAll(params);
    //console.log(result);
    return {
      ...result,
      page: params.page,
      limit: params.limit
    };
  }

  async getById(id: string, userId?: string, userRole?: string): Promise<Student | null> {
    // Ownership check: users can only view their own profile
    if ( userRole === "student" && id !== userId ) {
      throw new ForbiddenError("You can only view your own profile");
    }
    return this.studentRepository.findById(id);
  }

  async getStudentWithHistory(registration: string): Promise<any> {
    const student = await this.studentRepository.findByRegistration?.(registration);
    if (!student) return null;

    let transactions: any[] = [];
    if (this.borrowRepository) {
      transactions = await this.borrowRepository.GetAllTransactionsByStatus('ISSUED', registration);
      const requestedTransactions = await this.borrowRepository.GetAllTransactionsByStatus('REQUESTED', registration);
      const overdueTransactions = await this.borrowRepository.GetAllTransactionsByStatus('OVERDUE', registration);
      const returnedTransactions = await this.borrowRepository.GetAllTransactionsByStatus('RETURNED', registration);
      transactions = [...transactions, ...requestedTransactions, ...overdueTransactions, ...returnedTransactions];
    }

    return {
      student,
      transactions,
      activeBorrows: transactions.filter(t => t.status === 'ISSUED').length,
      pendingRequests: transactions.filter(t => t.status === 'REQUESTED').length,
      overdueBooks: transactions.filter(t => t.status === 'OVERDUE').length,
    };
  }

  async update(id: string, dto: UpdateStudentDTO, userId?: string, userRole?: string): Promise<Student | null> {
    // Ownership check: users can only update their own profile
    if (userRole === "student" && id !== userId) {
      throw new ForbiddenError("You can only update your own profile");
    }

    // Students may edit their own details, but not their identity keys
    // (Roll / Registration), which are used for login and referenced by
    // borrow transactions. Only librarians can change those.
    if (userRole === "student") {
      const { Roll, Registration, ...rest } = dto;
      dto = rest;
    }

    // Hash the password if the caller is changing it, so we never store it in plain text.
    if (dto.Password) {
      dto = { ...dto, Password: await this.passwordHasher.hashPassword(dto.Password) };
    }

    return this.studentRepository.update(id, dto);
  }

  async delete(id: string): Promise<boolean> {
    // Check if student has active borrows
    const student = await this.studentRepository.findById(id);
    if (student && this.borrowRepository) {
      const activeBorrows = await this.borrowRepository.CountActiveBorrowsByStudent(student.Registration);
      if (activeBorrows > 0) {
        throw new ConflictError(`Cannot delete this student. They have ${activeBorrows} book(s) currently borrowed.`);
      }
    }

    if (student) {
      const { deleteImageFromCloudflare } = await import('../utils/CloudflareImages.js');

      await Promise.allSettled([
        deleteImageFromCloudflare(student.PhotoUrl),
        deleteImageFromCloudflare(student.qrCode),
      ]);
    }

    return this.studentRepository.delete(id);
  }

  async generateQRCode(id: string, userId?: string, userRole?: string): Promise<string | null> {
    // Ownership check: only students can only generate their own QR code
    // Librarians can generate for any student
    if (userRole === "student" && id !== userId) {
      throw new ForbiddenError("You can only generate your own QR code");
    }
    
    const student = await this.studentRepository.findById(id);
    if (!student) return null;
    
    try {
      // Generate QR code with STUDENT REGISTRATION as the encoded data
      const qrCodeBase64 = await this.qrCodeService.generate(student.Registration);
      
      // Upload the QR code image to Cloudflare R2
      const { uploadImageToCloudflare } = await import('../utils/CloudflareImages.js');
      const filename = `qrcodes/student_${student.Registration}_${Date.now()}.png`;
      const qrCodeImageUrl = await uploadImageToCloudflare(`data:image/png;base64,${qrCodeBase64}`, filename);
      
      // Store ONLY the image URL, the QR data itself (registration) is encoded in the image
      await this.studentRepository.update(id, { qrCode: qrCodeImageUrl });
      return qrCodeImageUrl;
    } catch (error) {
      console.error('QR code generation/upload error:', error);
      throw error;
    }
  }

  async getByQRCode(qrCode: string): Promise<Student | null> {
    return this.studentRepository.findByQRCode(qrCode);
  }
}
