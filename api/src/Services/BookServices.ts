import { IBookRepository } from "../Repositories/IBookRepository.js";
import { AddNewBookDTO, UpdateBookDTO } from "../DTOs/BookDTO.js";
import { Book } from "../Entities/Book.js";

export class BookServices {
    constructor(private bookRepository: IBookRepository) {}

    async addNewBook(dto: AddNewBookDTO): Promise<Book> {
        const book = await this.bookRepository.addNewBook(dto);
        return book;
    }

    async removeBook(id: string): Promise<boolean> {
        return this.bookRepository.removeBook(id);
    }

    async displayBookDetails(id: string): Promise<Book | null> {
        const book = await this.bookRepository.displayBookInfo(id);
        return book;
    }

    async getAll(params: { page: number; limit: number; search?: string }): Promise<{ 
        books: Book[]; 
        total: number; 
        page: number; 
        limit: number;
        totalPages: number;
    }> {
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
        if (!query || query.trim() === '') {
            throw new Error('Search query cannot be empty');
        }
        return this.bookRepository.search(query);
    }

    async getByQRCode(qrCode: string): Promise<Book | null> {
        return this.bookRepository.getByQRCode(qrCode);
    }

    async create(dto: AddNewBookDTO): Promise<Book> {
        return this.bookRepository.addNewBook(dto);
    }

    async update(id: string, dto: UpdateBookDTO): Promise<Book | null> {
        // Business logic: Validate available copies
        if (dto.AvailableCopies !== undefined && dto.TotalCopies !== undefined) {
            if (dto.AvailableCopies > dto.TotalCopies) {
                throw new Error("Available copies cannot exceed total copies");
            }
        }

        return this.bookRepository.update(id, dto);
    }
}