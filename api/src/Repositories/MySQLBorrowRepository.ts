import { ResultSetHeader, RowDataPacket } from "mysql2";
import pool from "../config/database.js";
import { Book } from "../Entities/Book.js";
import { IBorrowRepository } from "./IBorrowRepository.js";
import { error } from "console";
import { Transaction } from "../Entities/Transaction.js";
import { connect } from "http2";


export class MySQLTransactionRepository implements IBorrowRepository{
    async BorrowANewBook(BookId: string,StudentReg: string): Promise<Partial<Transaction> | null> {
        try{
            const [book] = await pool.execute<RowDataPacket[]>("Select * from Books where id = ?",[BookId]);
            if(book.length == 0){
                return null;
            }else{
                const updatedcopies = book[0].AvailableCopies - 1;
                const [result] = await pool.execute<RowDataPacket[]>("update Books set AvailableCopies = ? where id = ?",[updatedcopies, BookId]);
                const[transaction] = await pool.execute<ResultSetHeader>("insert into Transactions (BookId, StudentReg, BorrowDate) values (?, ?, NOW())", [BookId, StudentReg]);
                const [insertedRow] = await pool.execute<RowDataPacket[]>(
                    "SELECT * FROM Transactions WHERE id = ?", 
                    [transaction.insertId]
                );
                return {
                    id: insertedRow[0].id,
                    bookId: BookId,
                    studentReg: StudentReg,
                    borrowDate: insertedRow[0].BorrowDate,
                    dueDate: insertedRow[0].DueDate
                }  as Partial<Transaction>;
            }
        }catch(error){
            console.log("Error database operation");
            return null;
        }
    }

    async ReturnBorrowedBook(BookId: String, StudentReg: string): Promise<Partial<Transaction | null>> {
        try{
            const [book] = await pool.execute<RowDataPacket[]>("Select * from Books where id = ?",[BookId]);
            const updatedCopies = book[0].AvailableCopies + 1;
            const [result] = await pool.execute<RowDataPacket[]>("update Books set AvailableCopies = ? where id = ?",[updatedCopies, BookId]);
             const connection = await pool.getConnection();
            await connection.execute(`update Transaction set returnDate = NOW() ,status= "RETURNED" WHERE studentReg = ? and bookId = ?`,[StudentReg,BookId])
            const [transaction] = await connection.execute<RowDataPacket[]>(
                    `SELECT id,bookId,studentReg,status,returnDate FROM Transactions WHERE studentReg = ? and bookId = ?`, 
                    [StudentReg,BookId]
                );
            return transaction as Partial<Transaction>;
        }catch(e){
            console.log("Error in transaction");
            return null;
        }
    }
}