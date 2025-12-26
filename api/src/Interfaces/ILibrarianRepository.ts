import { Librarian } from "../Entities/Librarian.js";

export interface ILibrarianRepository {
  create(data: Partial<Librarian>): Promise<Librarian>;
  findAll(params: { page: number; limit: number; search?: string }): Promise<{ librarians: Librarian[]; total: number }>;
  findById(id: string): Promise<Librarian | null>;
  findByEmail(email: string): Promise<Librarian | null>;
  update(id: string, data: Partial<Librarian>): Promise<Librarian | null>;
  delete(id: string): Promise<boolean>;
}
