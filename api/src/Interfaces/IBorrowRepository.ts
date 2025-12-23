import { Book } from "../Entities/Book.js";
import { Transaction } from "../Entities/Transaction.js";

export interface IBorrowRepository{
    RequestANewBook(BookId: string, StudentReg: string): Promise<Partial<Transaction>|null>;
    ConfirmRequestForBook(BookId: string, StudentReg: string): Promise<Partial<Transaction>|null>;
    ReturnBorrowedBook(BookId: String, StudentReg: string): Promise<Partial<Transaction>|null>;
}