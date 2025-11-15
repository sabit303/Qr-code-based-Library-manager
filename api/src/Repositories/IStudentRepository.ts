import { Student } from "../Entities/Student.js";

export interface IStudentRepository {
  create(data: Partial<Student>): Promise<Student>;
  findAll(params: { page: number; limit: number; search?: string }): Promise<{ students: Student[]; total: number }>;
  findById(id: string): Promise<Student | null>;
  findByQRCode(qrCode: string): Promise<Student | null>;
  update(id: string, data: Partial<Student>): Promise<Student | null>;
  delete(id: string): Promise<boolean>;
}
