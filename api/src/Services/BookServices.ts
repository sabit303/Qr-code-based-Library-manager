import { IBookRepository } from "../Interfaces/IBookRepository.js";
import { IBorrowRepository } from "../Interfaces/IBorrowRepository.js";
import { AddNewBookDTO, UpdateBookDTO } from "../DTOs/BookDTO.js";
import { Book } from "../Entities/Book.js";
import { BadRequestError, NotFoundError, ConflictError } from "../errors/AppError.js";

export class BookServices {
    constructor(
        private bookRepository: IBookRepository,
        private borrowRepository?: IBorrowRepository
    ) {}

    // ✅ Create a new book with domain rules
    async addNewBook(dto: AddNewBookDTO): Promise<Book> {
        // Business validation
        if (!dto.Name || dto.Name.trim() === "") {
            throw new BadRequestError("Book name is required");
        }
        if (!dto.AuthorName || dto.AuthorName.trim() === "") {
            throw new BadRequestError("Author name is required");
        }
        if (dto.TotalCopies <= 0) {
            throw new BadRequestError("Total copies must be greater than 0");
        }

        // Check if book already exists (by name+author)
        const existing = await this.bookRepository.search(dto.Name);
        if (existing.some(b => b.AuthorName === dto.AuthorName)) {
            console.log("this happend");
            throw new ConflictError("A book with the same name and author already exists");
        }

        // Domain rule: AvailableCopies = TotalCopies on creation
        dto.AvailableCopies = dto.TotalCopies;

        return this.bookRepository.addNewBook(dto);
    }

    // ❗ Blocking deletion if book is currently borrowed
    async removeBook(id: string): Promise<boolean> {
        const book = await this.bookRepository.getById(id);
        if (!book) throw new NotFoundError("Book not found");

        // Check if book has active borrows
        if (this.borrowRepository) {
            const activeBorrows = await this.borrowRepository.CountActiveBorrowsByBook(id);
            if (activeBorrows > 0) {
                throw new ConflictError(`Cannot delete this book. ${activeBorrows} copy(ies) currently borrowed by student(s).`);
            }
        }

        return this.bookRepository.removeBook(id);
    }

    async displayBookDetails(id: string): Promise<Book | null> {
        return this.bookRepository.displayBookInfo(id);
    }

    // Add pagination logic + validation
    async getAll(params: { page: number; limit: number; search?: string }) {
        if (params.page <= 0) throw new BadRequestError("Page must be >= 1");
        if (params.limit <= 0) throw new BadRequestError("Limit must be >= 1");

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
            throw new BadRequestError("Search query cannot be empty");
        }

        return this.bookRepository.search(query);
    }

    async getByQRCode(qrCode: string): Promise<Book | null> {
        if (!qrCode.trim()) throw new BadRequestError("QR Code cannot be empty");
        return this.bookRepository.getByQRCode(qrCode);
    }

    // Proper update with validations + existence check
    async update(id: string, dto: UpdateBookDTO): Promise<Book | null> {
        const existing = await this.bookRepository.getById(id);
        if (!existing) throw new NotFoundError("Book not found");

        // Business logic: AvailableCopies must not exceed TotalCopies
        if (
            dto.AvailableCopies !== undefined &&
            dto.TotalCopies !== undefined &&
            dto.AvailableCopies > dto.TotalCopies
        ) {
            throw new BadRequestError("Available copies cannot exceed total copies");
        }

        return this.bookRepository.update(id, dto);
    }
}
