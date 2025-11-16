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

    async displayBookInfo(Id: String): Promise<Book | null> {
        const query = 'Select * from Books where Id = ?';
        const [rows] = await pool.execute<RowDataPacket[]>(query, [Id]);
        
        if(rows.length === 0) return null;

        return new Book(rows[0] as Partial<Book>);

    }
}