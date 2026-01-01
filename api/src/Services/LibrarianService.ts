import { ILibrarianRepository } from "../Interfaces/ILibrarianRepository.js";
import { CreateLibrarianDTO, UpdateLibrarianDTO } from "../DTOs/LibrarianDTO.js";
import { Librarian } from "../Entities/Librarian.js";
import { PasswordHasher } from "../Helper/passHash.js";

export class LibrarianService {
  constructor(
    private librarianRepository: ILibrarianRepository,
    private passwordHasher: PasswordHasher
  ) {}

  async create(dto: CreateLibrarianDTO): Promise<Librarian> {
    const hashedPassword = await this.passwordHasher.hashPassword(dto.password);
    
    return this.librarianRepository.create({ 
      ...dto, 
      password: hashedPassword
    });
  }

  async getAll(params: { page: number; limit: number; search?: string }): Promise<{ librarians: Librarian[]; total: number; page: number; limit: number }> {
    const result = await this.librarianRepository.findAll(params);
    return {
      ...result,
      page: params.page,
      limit: params.limit
    };
  }

  async getById(id: string, userId?: string, userRole?: string): Promise<Librarian | null> {
    // Ownership check: users can only view their own profile
    if (userId && id !== userId) {
      throw new Error("You can only view your own profile");
    }
    return this.librarianRepository.findById(id);
  }

  async update(id: string, dto: UpdateLibrarianDTO, userId?: string, userRole?: string): Promise<Librarian | null> {
    // Ownership check: users can only update their own profile
    if (userId && id !== userId) {
      throw new Error("You can only update your own profile");
    }
    
    // If password is being updated, hash it
    if (dto.password) {
      dto.password = await this.passwordHasher.hashPassword(dto.password);
    }
    
    return this.librarianRepository.update(id, dto);
  }

  async delete(id: string): Promise<boolean> {
    return this.librarianRepository.delete(id);
  }

  async getByEmail(email: string): Promise<Librarian | null> {
    return this.librarianRepository.findByEmail(email);
  }
}
