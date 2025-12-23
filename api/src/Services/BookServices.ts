import { IBookRepository } from "../Interfaces/IBookRepository.js";
import { AddNewBookDTO, UpdateBookDTO } from "../DTOs/BookDTO.js";
import { Book } from "../Entities/Book.js";

export class BookServices {
    constructor(private bookRepository: IBookRepository) {}

    // ✅ Create a new book with domain rules
    async addNewBook(dto: AddNewBookDTO): Promise<Book> {
        // Business validation
        if (!dto.Name || dto.Name.trim() === "") {
            throw new Error("Book name is required");
        }
        if (!dto.AuthorName || dto.AuthorName.trim() === "") {
            throw new Error("Author name is required");
        }
        if (dto.TotalCopies <= 0) {
            throw new Error("Total copies must be greater than 0");
        }

        // Check if book already exists (by name+author)
        const existing = await this.bookRepository.search(dto.Name);
        if (existing.some(b => b.AuthorName === dto.AuthorName)) {
            throw new Error("A book with the same name and author already exists");
        }

        // Domain rule: AvailableCopies = TotalCopies on creation
        dto.AvailableCopies = dto.TotalCopies;

        return this.bookRepository.addNewBook(dto);
    }

    // ❗ Blocking deletion if book is currently borrowed (future rule)
    async removeBook(id: string): Promise<boolean> {
        const book = await this.bookRepository.getById(id);
        if (!book) throw new Error("Book not found");

        // Example future rule (if you add transactions)
        // const borrowedCount = await this.transactionRepo.countActiveBorrows(id);
        // if (borrowedCount > 0) {
        //     throw new Error("Cannot delete a book that is currently borrowed");
        // }

        return this.bookRepository.removeBook(id);
    }

    async displayBookDetails(id: string): Promise<Book | null> {
        return this.bookRepository.displayBookInfo(id);
    }

    // Add pagination logic + validation
    async getAll(params: { page: number; limit: number; search?: string }) {
        if (params.page <= 0) throw new Error("Page must be >= 1");
        if (params.limit <= 0) throw new Error("Limit must be >= 1");

        const result = await this.bookRepository.getAll(params);

        return {
            ...result,
            page: params.page,
            limit: params.limit,
            totalPages: Math.ceil(result.total / params.limit)
        };
    }

    async getById(id: string): Promise<Book | null> {
        return this.bookRepository.getById(id);
    }

    async search(query: string): Promise<Book[]> {
        if (!query || query.trim() === "") {
            throw new Error("Search query cannot be empty");
        }

        return this.bookRepository.search(query);
    }

    async getByQRCode(qrCode: string): Promise<Book | null> {
        if (!qrCode.trim()) throw new Error("QR Code cannot be empty");
        return this.bookRepository.getByQRCode(qrCode);
    }

    // Proper update with validations + existence check
    async update(id: string, dto: UpdateBookDTO): Promise<Book | null> {
        const existing = await this.bookRepository.getById(id);
        if (!existing) throw new Error("Book not found");

        // Business logic: AvailableCopies must not exceed TotalCopies
        if (
            dto.AvailableCopies !== undefined &&
            dto.TotalCopies !== undefined &&
            dto.AvailableCopies > dto.TotalCopies
        ) {
            throw new Error("Available copies cannot exceed total copies");
        }

        return this.bookRepository.update(id, dto);
    }
}
