import { Book } from "../Entities/Book.js";

export interface IBookRepository {
    addNewBook(data: Partial<Book>): Promise<Book>;
    removeBook(id: string): Promise<boolean>;
    displayBookInfo(id: string): Promise<Book | null>;
    getAll(params: { page: number; limit: number; search?: string }): Promise<{ books: Book[]; total: number }>;
    getById(id: string): Promise<Book | null>;
    search(query: string): Promise<Book[]>;
    getByQRCode(qrCode: string): Promise<Book | null>;
    update(id: string, data: Partial<Book>): Promise<Book | null>;
}