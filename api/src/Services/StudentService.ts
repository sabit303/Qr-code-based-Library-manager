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
    const qrCode = await this.qrCodeService.generate(dto.Registration);
    const hashedPassword = await this.passwordHasher.hashPassword(dto.Password);
    
    return this.studentRepository.create({ 
      ...dto, 
      Password: hashedPassword,
      qrCode 
    });
  }
  async getAll(params: { page: number; limit: number; search?: string }): Promise<{ students: Student[]; total: number; page: number; limit: number }> {
    const result = await this.studentRepository.findAll(params);
    return {
      ...result,
      page: params.page,
      limit: params.limit
    };
  }

  async getById(id: string): Promise<Student | null> {
    return this.studentRepository.findById(id);
  }

  async update(id: string, dto: UpdateStudentDTO): Promise<Student | null> {
    return this.studentRepository.update(id, dto);
  }

  async delete(id: string): Promise<boolean> {
    return this.studentRepository.delete(id);
  }

  async generateQRCode(id: string): Promise<string | null> {
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
