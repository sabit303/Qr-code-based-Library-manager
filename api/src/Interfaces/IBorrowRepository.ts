import { Book } from "../Entities/Book.js";
import { Transaction } from "../Entities/Transaction.js";

export interface IBorrowRepository{
    RequestANewBook(BookId: string, StudentReg: string, returnDate?: string): Promise<Partial<Transaction>|null>;
    ConfirmRequestForBook(BookId: string, StudentReg: string): Promise<Partial<Transaction>|null>;
    GetAllTransactionsByStatus(status: 'ISSUED' | 'RETURNED' | 'OVERDUE' | 'REQUESTED', studentReg?: string, bookId?: string): Promise<Transaction[]>;
    ReturnBorrowedBook(BookId: string, StudentReg: string): Promise<Partial<Transaction>|null>;
    CountActiveBorrowsByBook(bookId: string): Promise<number>;
    CountActiveBorrowsByStudent(studentReg: string): Promise<number>;
    GetNextAvailableDateForBook(bookId: string): Promise<Date | null>;
}
