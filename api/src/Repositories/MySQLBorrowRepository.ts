import { ResultSetHeader, RowDataPacket } from "mysql2";
import pool from "../config/database.js";
import { Book } from "../Entities/Book.js";
import { IBorrowRepository } from "../Interfaces/IBorrowRepository.js";
import { error } from "console";
import { Transaction } from "../Entities/Transaction.js";
import { connect } from "http2";


export class MySQLTransactionRepository implements IBorrowRepository{
    async RequestANewBook(BookId: string,StudentReg: string): Promise<Partial<Transaction> | null> {
        try{
            const [book] = await pool.execute<RowDataPacket[]>("SELECT * FROM books WHERE id = ?",[BookId]);
            if(book.length == 0){
                return null;
            }else{
                const[transaction] = await pool.execute<ResultSetHeader>("INSERT INTO transactions (bookId, studentReg, status, createdAt) VALUES (?, ?, 'REQUESTED', NOW())", [BookId, StudentReg]);
                const [insertedRow] = await pool.execute<RowDataPacket[]>(
                    "SELECT * FROM transactions WHERE studentReg = ? AND bookId = ?", 
                    [StudentReg,BookId]
                );
                return {
                    id: insertedRow[0].id,
                    bookId: BookId,
                    studentReg: StudentReg,
                    status: insertedRow[0].status,
                    borrowDate: insertedRow[0].borrowedDate,
                    dueDate: insertedRow[0].dueDate
                }  as Partial<Transaction>;
            }
        }catch(error){
            console.log("Error database operation");
            return null;
        }
    }

    async ConfirmRequestForBook(BookId: string,StudentReg: string): Promise<Partial<Transaction>|null> {
        try{
            const [book] = await pool.execute<RowDataPacket[]>("SELECT * FROM books WHERE id = ?",[BookId]);
            const updatedcopies = book[0].availableCopies - 1;
                const [result] = await pool.execute<RowDataPacket[]>("UPDATE books SET availableCopies = ? WHERE id = ?",[updatedcopies, BookId]);
                const[transaction] = await pool.execute<ResultSetHeader>(`UPDATE transactions SET status = 'ISSUED', borrowedDate = NOW() WHERE studentReg = ? AND bookId = ?`, [ StudentReg, BookId]);
                const [insertedRow] = await pool.execute<RowDataPacket[]>(
                    "SELECT * FROM transactions WHERE studentReg = ? AND bookId = ?",
                    [StudentReg,BookId]
                );
                return {
                    id: insertedRow[0].id,
                    bookId: BookId,
                    studentReg: StudentReg,
                    status: insertedRow[0].status,
                    borrowDate: insertedRow[0].borrowedDate,
                    dueDate: insertedRow[0].dueDate
                }  as Partial<Transaction>;
            
        }catch(error){
            console.log("Error database operation");
            return null;
        }
    }


    async ReturnBorrowedBook(BookId: String, StudentReg: string): Promise<Partial<Transaction | null>> {
        try{
            const [book] = await pool.execute<RowDataPacket[]>("SELECT * FROM books WHERE id = ?",[BookId]);
            const updatedCopies = book[0].availableCopies + 1;
            const [result] = await pool.execute<RowDataPacket[]>("UPDATE books SET availableCopies = ? WHERE id = ?",[updatedCopies, BookId]);
             const connection = await pool.getConnection();
            await connection.execute(`UPDATE transactions SET returnDate = NOW(), status = 'RETURNED' WHERE studentReg = ? AND bookId = ?`,[StudentReg,BookId])
            const [transaction] = await connection.execute<RowDataPacket[]>(
                    `SELECT id, bookId, studentReg, status, returnDate FROM transactions WHERE studentReg = ? AND bookId = ?`, 
                    [StudentReg,BookId]
                );
            return transaction as Partial<Transaction>;
        }catch(e){
            console.log("Error in transaction");
            return null;
        }
    }
}