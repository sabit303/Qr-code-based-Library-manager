import { ResultSetHeader, RowDataPacket } from "mysql2";
import pool from "../config/database.js";
import { Book } from "../Entities/Book.js";
import { IBorrowRepository } from "../Interfaces/IBorrowRepository.js";
import { error } from "console";
import { Transaction } from "../Entities/Transaction.js";
import { connect } from "http2";


export class MySQLTransactionRepository implements IBorrowRepository {
    async RequestANewBook(BookId: string, StudentReg: string, returnDate?: string): Promise<Partial<Transaction> | null> {
        try {
            const [book] = await pool.execute<RowDataPacket[]>("SELECT * FROM books WHERE id = ?", [BookId]);
            if (book.length == 0) {
                return null;
            } else {
                // Store the student's requested return date as the dueDate up front,
                // so it is carried through to issue time.
                if (returnDate) {
                    await pool.execute<ResultSetHeader>(
                        "INSERT INTO transactions (bookId, studentReg, status, createdAt, dueDate) VALUES (?, ?, 'REQUESTED', NOW(), ?)",
                        [BookId, StudentReg, new Date(returnDate)]
                    );
                } else {
                    await pool.execute<ResultSetHeader>(
                        "INSERT INTO transactions (bookId, studentReg, status, createdAt) VALUES (?, ?, 'REQUESTED', NOW())",
                        [BookId, StudentReg]
                    );
                }
                const [insertedRow] = await pool.execute<RowDataPacket[]>(
                    "SELECT * FROM transactions WHERE studentReg = ? AND bookId = ? ORDER BY createdAt DESC, id DESC LIMIT 1",
                    [StudentReg, BookId]
                );
                return {
                    id: insertedRow[0].id,
                    bookId: BookId,
                    studentReg: StudentReg,
                    status: insertedRow[0].status,
                    borrowDate: insertedRow[0].borrowedDate,
                    dueDate: insertedRow[0].dueDate
                } as Partial<Transaction>;
            }
        } catch (error) {
            console.log("Error database operation");
            return null;
        }
    }

    async ConfirmRequestForBook(BookId: string, StudentReg: string, returnDate?: string): Promise<Partial<Transaction> | null> {
        try {
            const [book] = await pool.execute<RowDataPacket[]>("SELECT * FROM books WHERE id = ?", [BookId]);
            const updatedcopies = book[0].availableCopies - 1;
            const [result] = await pool.execute<RowDataPacket[]>("UPDATE books SET availableCopies = ? WHERE id = ?", [updatedcopies, BookId]);

            const [requestRows] = await pool.execute<RowDataPacket[]>(
                `SELECT id
                 FROM transactions
                 WHERE studentReg = ? AND bookId = ? AND status = 'REQUESTED'
                 ORDER BY createdAt DESC, id DESC
                 LIMIT 1`,
                [StudentReg, BookId]
            );

            if (requestRows.length === 0) {
                return null;
            }

            const transactionId = requestRows[0].id;
            
            let updateQuery = `UPDATE transactions SET status = 'ISSUED', borrowedDate = NOW()`;
            const params: any[] = [];
            
            if (returnDate) {
                updateQuery += `, dueDate = ?`;
                params.push(new Date(returnDate));
            }
            
            updateQuery += ` WHERE id = ?`;
            params.push(transactionId);
            
            const [transaction] = await pool.execute<ResultSetHeader>(updateQuery, params);
            const [insertedRow] = await pool.execute<RowDataPacket[]>(
                "SELECT * FROM transactions WHERE id = ?",
                [transactionId]
            );
            console.log(insertedRow[0]);
            return {
                id: insertedRow[0].id,
                bookId: BookId,
                studentReg: StudentReg,
                status: insertedRow[0].status,
                borrowDate: insertedRow[0].borrowedDate,
                dueDate: insertedRow[0].dueDate
            } as Partial<Transaction>;

        } catch (error) {
            console.log("Error database operation");
            return null;
        }
    }


    async GetAllTransactionsByStatus(status: string, studentReg?: string, bookId?: string): Promise<Transaction[]> {
        try {
            let query = `SELECT
                t.id,
                t.bookId,
                t.studentReg,
                t.status,
                t.borrowedDate,
                t.dueDate,
                t.returnDate,
                s.Name as studentName,
                s.Registration as studentRegistration,
                s.Department as studentDepartment,
                s.Session as studentSession,
                b.name as bookTitle,
                b.authorName as bookAuthor,
                b.coverUrl as bookCoverUrl
            FROM transactions t
            LEFT JOIN students s ON t.studentReg = s.Registration
            LEFT JOIN books b ON t.bookId = b.id
            WHERE t.status = ?`;
            const params: any[] = [status];

            if (studentReg) {
                query += ` AND t.studentReg = ?`;
                params.push(studentReg);
            }

            if (bookId) {
                query += ` AND t.bookId = ?`;
                params.push(bookId);
            }

            const [rows] = await pool.execute<RowDataPacket[]>(query, params);

            return rows.map(row => ({
                id: row.id,
                bookId: row.bookId,
                studentReg: row.studentReg,
                status: row.status,
                borrowedDate: row.borrowedDate,
                dueDate: row.dueDate,
                returnDate: row.returnDate,
                coverUrl: row.bookCoverUrl,
                studentName: row.studentName,
                studentRegistration: row.studentRegistration,
                studentDepartment: row.studentDepartment,
                studentSession: row.studentSession,
                bookTitle: row.bookTitle,
                bookAuthor: row.bookAuthor
            })) as Transaction[];
        } catch (error) {
            console.log(error);
            throw error;
        }
    }

    async ReturnBorrowedBook(BookId: string, StudentReg: string): Promise<Partial<Transaction> | null> {
        const connection = await pool.getConnection();
        try {
            const [activeRows] = await connection.execute<RowDataPacket[]>(
                `SELECT id
                 FROM transactions
                 WHERE studentReg = ? AND bookId = ? AND status IN ('ISSUED', 'OVERDUE')
                 ORDER BY borrowedDate DESC, createdAt DESC, id DESC
                 LIMIT 1`,
                [StudentReg, BookId]
            );

            if (activeRows.length === 0) {
                return null;
            }

            const transactionId = activeRows[0].id;
            await connection.execute(
                "UPDATE books SET availableCopies = availableCopies + 1 WHERE id = ?",
                [BookId]
            );
            await connection.execute(
                `UPDATE transactions SET returnDate = NOW(), status = 'RETURNED' WHERE id = ?`,
                [transactionId]
            );
            const [transaction] = await connection.execute<RowDataPacket[]>(
                `SELECT id, bookId, studentReg, status, borrowedDate, dueDate, returnDate
                 FROM transactions
                 WHERE id = ?`,
                [transactionId]
            );
            return transaction[0] as Partial<Transaction>;
        } catch (e) {
            console.log("Error in transaction");
            return null;
        } finally {
            connection.release();
        }
    }

    async DeleteRequest(BookId: string, StudentReg: string): Promise<boolean> {
        try {
            const [result] = await pool.execute<ResultSetHeader>(
                "DELETE FROM transactions WHERE bookId = ? AND studentReg = ? AND status = 'REQUESTED'",
                [BookId, StudentReg]
            );
            return result.affectedRows > 0;
        } catch (error) {
            console.log("Error deleting request:", error);
            return false;
        }
    }

    async CountActiveBorrowsByBook(bookId: string): Promise<number> {
        try {
            const [rows] = await pool.execute<RowDataPacket[]>(
                "SELECT COUNT(*) as count FROM transactions WHERE bookId = ? AND status = 'ISSUED'",
                [bookId]
            );
            return rows[0].count || 0;
        } catch (error) {
            console.log("Error counting active borrows for book:", error);
            return 0;
        }
    }

    async CountActiveBorrowsByStudent(studentReg: string): Promise<number> {
        try {
            const [rows] = await pool.execute<RowDataPacket[]>(
                "SELECT COUNT(*) as count FROM transactions WHERE studentReg = ? AND status IN ('ISSUED', 'OVERDUE')",
                [studentReg]
            );
            return rows[0].count || 0;
        } catch (error) {
            console.log("Error counting active borrows for student:", error);
            return 0;
        }
    }

    async GetNextAvailableDateForBook(bookId: string): Promise<Date | null> {
        try {
            const [rows] = await pool.execute<RowDataPacket[]>(
                "SELECT dueDate FROM transactions WHERE bookId = ? AND status IN ('ISSUED', 'OVERDUE') ORDER BY dueDate ASC LIMIT 1",
                [bookId]
            );
            if (rows.length > 0 && rows[0].dueDate) {
                return new Date(rows[0].dueDate);
            }
            return null;
        } catch (error) {
            console.log("Error getting next available date for book:", error);
            return null;
        }
    }
}
