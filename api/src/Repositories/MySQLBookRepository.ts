import { ResultSetHeader, RowDataPacket } from "mysql2";
import pool from "../config/database.js";
import { Book } from "../Entities/Book.js";
import { IBookRepository } from "../Interfaces/IBookRepository.js";
import { v4 as uuidv4 } from "uuid";

export class MySQLBookRepository implements IBookRepository {


    private mapRowToBook(row: RowDataPacket): Book {
        return new Book({
            Id: row.id,
            Name: row.name,
            AuthorName: row.authorName,
            Edition: row.edition,
            Genre: row.genre,
            TotalCopies: row.totalCopies,
            AvailableCopies: row.availableCopies,
        });
    }


    async addNewBook(data: Partial<Book>): Promise<Book> {
        const id = uuidv4();

        const query = `
            INSERT INTO books (id, name, authorName, edition, genre, totalCopies, availableCopies)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `;

        await pool.execute(query, [
            id,
            data.Name,
            data.AuthorName,
            data.Edition,
            data.Genre,
            data.TotalCopies,
            data.AvailableCopies
        ]);

        return new Book({
            Id: id,
            Name: data.Name!,
            AuthorName: data.AuthorName!,
            Edition: data.Edition!,
            Genre: data.Genre!,
            TotalCopies: data.TotalCopies!,
            AvailableCopies: data.AvailableCopies!,
        });
    }

    async removeBook(id: string): Promise<boolean> {
        const query = `DELETE FROM books WHERE id = ?`;
        const [result] = await pool.execute<ResultSetHeader>(query, [id]);

        return result.affectedRows > 0;
    }

    async displayBookInfo(id: string): Promise<Book | null> {
        const [rows] = await pool.execute<RowDataPacket[]>(
            "SELECT * FROM books WHERE id = ?",
            [id]
        );

        return rows.length ? this.mapRowToBook(rows[0]) : null;
    }

    async getAll(params: { page: number; limit: number; search?: string })
        : Promise<{ books: Book[]; total: number }> {
        try {
            let countQuery = 'SELECT COUNT(*) AS total FROM books';
            let selectQuery = 'SELECT * FROM books';

            const countParams: any[] = [];
            const selectParams: any[] = [];

            if (params.search) {
                const searchCondition =
                    ' WHERE name LIKE ? OR authorName LIKE ? OR genre LIKE ?';

                countQuery += searchCondition;
                selectQuery += searchCondition;

                const searchTerm = `%${params.search}%`;
                countParams.push(searchTerm, searchTerm, searchTerm);
                selectParams.push(searchTerm, searchTerm, searchTerm);
            }

            // Count
            const [countRows] = await pool.execute<RowDataPacket[]>(countQuery, countParams);
            const total = Number(countRows[0]?.total || countRows[0]?.['COUNT(*)'] || 0);

            // ✅ Force numbers
            const page = Number(params.page);
            const limit = Number(params.limit);

            if (!Number.isInteger(page) || !Number.isInteger(limit)) {
                throw new Error("Invalid pagination parameters");
            }

            const offset = (page - 1) * limit;

            // Use string interpolation for LIMIT and OFFSET since MySQL prepared statements
            // can be strict about these parameters. Safe because we validated they are integers.
            selectQuery += ` ORDER BY name ASC LIMIT ${limit} OFFSET ${offset}`;

            const [rows] = await pool.execute<RowDataPacket[]>(selectQuery, selectParams);
            const books = rows.map(r => this.mapRowToBook(r));

            return { books, total };
        } catch (error) {
            console.error('Error in MySQLBookRepository.getAll:', error);
            throw error;
        }
    }

    async getById(id: string): Promise<Book | null> {
        const [rows] = await pool.execute<RowDataPacket[]>(
            "SELECT * FROM books WHERE id = ?",
            [id]
        );

        return rows.length ? this.mapRowToBook(rows[0]) : null;
    }

    async search(query: string): Promise<Book[]> {
        const q = `%${query}%`;

        const [rows] = await pool.execute<RowDataPacket[]>(
            `
            SELECT * FROM books
            WHERE name LIKE ? OR authorName LIKE ? OR genre LIKE ?
            ORDER BY name ASC
            `,
            [q, q, q]
        );

        return rows.map(r => this.mapRowToBook(r));
    }

    // ----------------------------------------
    // QR CODE LOOKUP
    // ----------------------------------------
    async getByQRCode(qrCode: string): Promise<Book | null> {
        const [rows] = await pool.execute<RowDataPacket[]>(
            "SELECT * FROM books WHERE qrCode = ?",
            [qrCode]
        );

        return rows.length ? this.mapRowToBook(rows[0]) : null;
    }

    async update(id: string, data: Partial<Book>): Promise<Book | null> {
        const fields = Object.keys(data);
        if (fields.length === 0) return this.getById(id);

        const updates = fields.map(field => `${field} = ?`).join(", ");
        const values = fields.map(field => (data as any)[field]);

        const query = `UPDATE books SET ${updates} WHERE id = ?`;

        const [result] = await pool.execute<ResultSetHeader>(query, [
            ...values,
            id
        ]);

        if (result.affectedRows === 0) return null;

        return this.getById(id);
    }
}
