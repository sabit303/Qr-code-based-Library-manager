import { ResultSetHeader, RowDataPacket } from "mysql2";
import pool from "../config/database.js";
import { Book } from "../Entities/Book.js";
import { IBookRepository } from "./IBookRepository.js";
import { v4 as uuidv4 } from 'uuid';



export class MySQLBookRepository implements IBookRepository{
    async addNewBook(data: Partial<Book>): Promise<Book> {
        const id = uuidv4();
        const book: Book ={
            Id: id,
            Name: data.Name || "",
            AuthorName: data.AuthorName || "",
            Edition: data.Edition || "",
            Genre: data.Genre || "",
            TotalCopies: data.TotalCopies || 0,
            AvailableCopies: data.TotalCopies || 0
        }
         const query = 'Insert into Books (Id, Name, AuthorName, Edition, Genre, TotalCopies, AvailableCopies) values(?,?,?,?,?,?,?)'
        await pool.execute(query,[
            id,
            data.Name,
            data.AuthorName,
            data.Edition,
            data.Genre,
            data.TotalCopies,
            data.AvailableCopies
        ]);
        return book;
        }

    async removeBook(Id: String): Promise<boolean> {
        const query = 'DELETE FROM Books WHERE Id = ?';
        const [result] = await pool.execute<ResultSetHeader>(query, [Id]);
        return result.affectedRows > 0;
    }    

    async displayBookInfo(id: string): Promise<Book | null> {
        const query = 'SELECT * FROM Books WHERE Id = ?';
        const [rows] = await pool.execute<RowDataPacket[]>(query, [id]);
        
        if (rows.length === 0) return null;

        return new Book(rows[0] as Partial<Book>);
    }

    async getAll(params: { page: number; limit: number; search?: string }): Promise<{ books: Book[]; total: number }> {
        let query = 'SELECT * FROM Books';
        let countQuery = 'SELECT COUNT(*) as total FROM Books';
        const queryParams: any[] = [];
        const countParams: any[] = [];

        if (params.search) {
            const searchCondition = ` WHERE Name LIKE ? OR AuthorName LIKE ? OR Genre LIKE ?`;
            query += searchCondition;
            countQuery += searchCondition;
            const searchTerm = `%${params.search}%`;
            queryParams.push(searchTerm, searchTerm, searchTerm);
            countParams.push(searchTerm, searchTerm, searchTerm);
        }

        // Get total count
        const [countRows] = await pool.execute<RowDataPacket[]>(countQuery, countParams);
        const total = countRows[0].total;

        // Add pagination
        const offset = (params.page - 1) * params.limit;
        query += ` ORDER BY Name ASC LIMIT ? OFFSET ?`;
        queryParams.push(params.limit, offset);

        const [rows] = await pool.execute<RowDataPacket[]>(query, queryParams);
        const books = rows.map(row => new Book(row as Partial<Book>));

        return { books, total };
    }

    async getById(id: string): Promise<Book | null> {
        const query = 'SELECT * FROM Books WHERE Id = ?';
        const [rows] = await pool.execute<RowDataPacket[]>(query, [id]);
        
        if (rows.length === 0) return null;
        
        return new Book(rows[0] as Partial<Book>);
    }

    async search(query: string): Promise<Book[]> {
        const searchQuery = 'SELECT * FROM Books WHERE Name LIKE ? OR AuthorName LIKE ? OR Genre LIKE ? ORDER BY Name ASC';
        const searchTerm = `%${query}%`;
        const [rows] = await pool.execute<RowDataPacket[]>(searchQuery, [searchTerm, searchTerm, searchTerm]);
        
        return rows.map(row => new Book(row as Partial<Book>));
    }

    async getByQRCode(qrCode: string): Promise<Book | null> {
        const query = 'SELECT * FROM Books WHERE qrCode = ?';
        const [rows] = await pool.execute<RowDataPacket[]>(query, [qrCode]);
        
        if (rows.length === 0) return null;
        
        return new Book(rows[0] as Partial<Book>);
    }

    async update(id: string, data: Partial<Book>): Promise<Book | null> {
        const updates: string[] = [];
        const values: any[] = [];

        // Build dynamic update query
        if (data.Name !== undefined) {
            updates.push('Name = ?');
            values.push(data.Name);
        }
        if (data.AuthorName !== undefined) {
            updates.push('AuthorName = ?');
            values.push(data.AuthorName);
        }
        if (data.Edition !== undefined) {
            updates.push('Edition = ?');
            values.push(data.Edition);
        }
        if (data.Genre !== undefined) {
            updates.push('Genre = ?');
            values.push(data.Genre);
        }
        if (data.TotalCopies !== undefined) {
            updates.push('TotalCopies = ?');
            values.push(data.TotalCopies);
        }
        if (data.AvailableCopies !== undefined) {
            updates.push('AvailableCopies = ?');
            values.push(data.AvailableCopies);
        }

        if (updates.length === 0) {
            return this.getById(id);
        }

        values.push(id);
        const query = `UPDATE Books SET ${updates.join(', ')} WHERE Id = ?`;
        
        const [result] = await pool.execute<ResultSetHeader>(query, values);
        
        if (result.affectedRows === 0) return null;
        
        return this.getById(id);
    }
}
        
        