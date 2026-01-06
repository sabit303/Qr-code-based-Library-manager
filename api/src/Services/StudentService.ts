import { IStudentRepository } from "../Interfaces/IStudentRepository.js";
import { CreateStudentDTO, UpdateStudentDTO } from "../DTOs/StudentDTO.js";
import { Student } from "../Entities/Student.js";
import { QRCodeService } from "./QRCodeService.js";
import { PasswordHasher } from "../Helper/passHash.js";

export class StudentService {
  constructor(
    private studentRepository: IStudentRepository,
    private qrCodeService: QRCodeService,
    private passwordHasher: PasswordHasher
  ) {}

  
  async create(dto: CreateStudentDTO): Promise<Student> {
    //const qrCode = await this.qrCodeService.generate(dto.Registration);
    const hashedPassword = await this.passwordHasher.hashPassword(dto.Password);
    
    return this.studentRepository.create({ 
      ...dto, 
      Password: hashedPassword,
      //qrCode 
    });
  }
  async getAll(params: { page: number; limit: number; }): Promise<{ students: Student[]; total: number; page: number; limit: number }> {
    console.log(params)
    const result = await this.studentRepository.findAll(params);
    console.log(result);
    return {
      ...result,
      page: params.page,
      limit: params.limit
    };
  }

  async getById(id: string, userId?: string, userRole?: string): Promise<Student | null> {
    // Ownership check: users can only view their own profile
    if (userId && id !== userId) {
      throw new Error("You can only view your own profile");
    }
    return this.studentRepository.findById(id);
  }

  async update(id: string, dto: UpdateStudentDTO, userId?: string, userRole?: string): Promise<Student | null> {
    // Ownership check: users can only update their own profile
    if (userId && id !== userId) {
      throw new Error("You can only update your own profile");
    }
    return this.studentRepository.update(id, dto);
  }

  async delete(id: string): Promise<boolean> {
    return this.studentRepository.delete(id);
  }

  async generateQRCode(id: string, userId?: string, userRole?: string): Promise<string | null> {
    // Ownership check: users can only generate their own QR code
    if (userId && id !== userId) {
      throw new Error("You can only generate your own QR code");
    }
    
    const student = await this.studentRepository.findById(id);
    if (!student) return null;
    
    const qrCode = await this.qrCodeService.generate(student.Registration);
    await this.studentRepository.update(id, { qrCode });
    return qrCode;
  }

  async getByQRCode(qrCode: string): Promise<Student | null> {
    return this.studentRepository.findByQRCode(qrCode);
  }
}
