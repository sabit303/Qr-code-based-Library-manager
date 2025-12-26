import { ILibrarianRepository } from "../Interfaces/ILibrarianRepository.js";
import { Librarian } from "../Entities/Librarian.js";
import pool from "../config/database.js";
import { RowDataPacket, ResultSetHeader } from "mysql2";
import { v4 as uuidv4 } from 'uuid';

export class MySQLLibrarianRepository implements ILibrarianRepository {
  async create(data: Partial<Librarian>): Promise<Librarian> {
    const id = uuidv4();
    const librarian: Librarian = {
      id,
      name: data.name || "",
      contact: data.contact,
      email: data.email || "",
      password: data.password || ""
    };

    const query = `
      INSERT INTO librarians (id, name, contact, email, password)
      VALUES (?, ?, ?, ?, ?)
    `;

    await pool.execute(query, [
      librarian.id,
      librarian.name,
      librarian.contact || null,
      librarian.email,
      librarian.password
    ]);

    return librarian;
  }

  async findAll(params: { page: number; limit: number; search?: string }): Promise<{ librarians: Librarian[]; total: number }> {
    let query = 'SELECT id, name, contact, email FROM librarians';
    let countQuery = 'SELECT COUNT(*) as total FROM librarians';
    const queryParams: any[] = [];
    const countParams: any[] = [];

    if (params.search) {
      const searchCondition = ` WHERE name LIKE ? OR email LIKE ?`;
      query += searchCondition;
      countQuery += searchCondition;
      
      const searchTerm = `%${params.search}%`;
      queryParams.push(searchTerm, searchTerm);
      countParams.push(searchTerm, searchTerm);
    }

    // Get total count
    const [countRows] = await pool.execute<RowDataPacket[]>(countQuery, countParams);
    const total = countRows[0].total;

    // Add pagination
    const offset = (params.page - 1) * params.limit;
    query += ` ORDER BY created_at DESC LIMIT ? OFFSET ?`;
    queryParams.push(params.limit, offset);

    const [rows] = await pool.execute<RowDataPacket[]>(query, queryParams);
    const librarians = rows.map(row => this.mapRowToLibrarian(row));

    return { librarians, total };
  }

  async findById(id: string): Promise<Librarian | null> {
    try {
      const query = 'SELECT id, name, contact, email FROM librarians WHERE id = ?';
      const [rows] = await pool.execute<RowDataPacket[]>(query, [id]);

      if (rows.length === 0) return null;
      
      return this.mapRowToLibrarian(rows[0]);
    } catch (e) {
      console.log("db error: " + e);
      return null;
    }
  }

  async findByEmail(email: string): Promise<Librarian | null> {
    const query = 'SELECT * FROM librarians WHERE email = ?';
    const [rows] = await pool.execute<RowDataPacket[]>(query, [email]);
    
    if (rows.length === 0) return null;
    
    return this.mapRowToLibrarianWithPassword(rows[0]);
  }

  async update(id: string, data: Partial<Librarian>): Promise<Librarian | null> {
    const updateFields: string[] = [];
    const values: any[] = [];

    if (data.name !== undefined) {
      updateFields.push('name = ?');
      values.push(data.name);
    }
    if (data.contact !== undefined) {
      updateFields.push('contact = ?');
      values.push(data.contact);
    }
    if (data.email !== undefined) {
      updateFields.push('email = ?');
      values.push(data.email);
    }
    if (data.password !== undefined) {
      updateFields.push('password = ?');
      values.push(data.password);
    }

    if (updateFields.length === 0) {
      return this.findById(id);
    }

    values.push(id);
    const query = `UPDATE librarians SET ${updateFields.join(', ')} WHERE id = ?`;

    const [result] = await pool.execute<ResultSetHeader>(query, values);

    if (result.affectedRows === 0) return null;

    return this.findById(id);
  }

  async delete(id: string): Promise<boolean> {
    const query = 'DELETE FROM librarians WHERE id = ?';
    const [result] = await pool.execute<ResultSetHeader>(query, [id]);

    return result.affectedRows > 0;
  }

  private mapRowToLibrarian(row: RowDataPacket): Librarian {
    return {
      id: row.id,
      name: row.name,
      contact: row.contact,
      email: row.email
    };
  }

  private mapRowToLibrarianWithPassword(row: RowDataPacket): Librarian {
    return {
      id: row.id,
      name: row.name,
      contact: row.contact,
      email: row.email,
      password: row.password
    };
  }
}
