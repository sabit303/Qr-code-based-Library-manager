import { IStudentRepository } from "./IStudentRepository.js";
import { Student } from "../Entities/Student.js";
import pool from "../config/database.js";
import { RowDataPacket, ResultSetHeader } from "mysql2";
import { v4 as uuidv4 } from 'uuid';

export class MySQLStudentRepository implements IStudentRepository {
  async create(data: Partial<Student>): Promise<Student> {
    const id = uuidv4();
    const student: Student = {
      id,
      Name: data.Name || "",
      Roll: data.Roll || "",
      Registration: data.Registration || "",
      Department: data.Department || "",
      Session: data.Session || "",
      ContactNumber: data.ContactNumber || "",
      Address: data.Address || "",
      qrCode: data.qrCode
    };

    const query = `
      INSERT INTO students (id, Name, Roll, Registration, Department, Session, ContactNumber, Address, qrCode)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;

    await pool.execute(query, [
      student.id,
      student.Name,
      student.Roll,
      student.Registration,
      student.Department,
      student.Session,
      student.ContactNumber,
      student.Address,
      student.qrCode || null
    ]);

    return student;
  }

  async findAll(params: { page: number; limit: number; search?: string }): Promise<{ students: Student[]; total: number }> {
    let query = 'SELECT * FROM students';
    let countQuery = 'SELECT COUNT(*) as total FROM students';
    const queryParams: any[] = [];
    const countParams: any[] = [];

    if (params.search) {
      const searchCondition = ` WHERE Name LIKE ? OR Roll LIKE ? OR Registration LIKE ? OR Department LIKE ?`;
      query += searchCondition;
      countQuery += searchCondition;
      
      const searchTerm = `%${params.search}%`;
      queryParams.push(searchTerm, searchTerm, searchTerm, searchTerm);
      countParams.push(searchTerm, searchTerm, searchTerm, searchTerm);
    }

    // Get total count
    const [countRows] = await pool.execute<RowDataPacket[]>(countQuery, countParams);
    const total = countRows[0].total;

    // Add pagination
    const offset = (params.page - 1) * params.limit;
    query += ` ORDER BY created_at DESC LIMIT ? OFFSET ?`;
    queryParams.push(params.limit, offset);

    const [rows] = await pool.execute<RowDataPacket[]>(query, queryParams);
    const students = rows.map(row => this.mapRowToStudent(row));

    return { students, total };
  }

  async findById(id: string): Promise<Student | null> {
    const query = 'SELECT * FROM students WHERE id = ?';
    const [rows] = await pool.execute<RowDataPacket[]>(query, [id]);
    
    if (rows.length === 0) return null;
    
    return this.mapRowToStudent(rows[0]);
  }

  async findByQRCode(qrCode: string): Promise<Student | null> {
    const query = 'SELECT * FROM students WHERE qrCode = ?';
    const [rows] = await pool.execute<RowDataPacket[]>(query, [qrCode]);
    
    if (rows.length === 0) return null;
    
    return this.mapRowToStudent(rows[0]);
  }

  async update(id: string, data: Partial<Student>): Promise<Student | null> {
    const updates: string[] = [];
    const values: any[] = [];

    // Build dynamic update query
    if (data.Name !== undefined) {
      updates.push('Name = ?');
      values.push(data.Name);
    }
    if (data.Roll !== undefined) {
      updates.push('Roll = ?');
      values.push(data.Roll);
    }
    if (data.Registration !== undefined) {
      updates.push('Registration = ?');
      values.push(data.Registration);
    }
    if (data.Department !== undefined) {
      updates.push('Department = ?');
      values.push(data.Department);
    }
    if (data.Session !== undefined) {
      updates.push('Session = ?');
      values.push(data.Session);
    }
    if (data.ContactNumber !== undefined) {
      updates.push('ContactNumber = ?');
      values.push(data.ContactNumber);
    }
    if (data.Address !== undefined) {
      updates.push('Address = ?');
      values.push(data.Address);
    }
    if (data.qrCode !== undefined) {
      updates.push('qrCode = ?');
      values.push(data.qrCode);
    }

    if (updates.length === 0) {
      return this.findById(id);
    }

    values.push(id);
    const query = `UPDATE students SET ${updates.join(', ')} WHERE id = ?`;
    
    const [result] = await pool.execute<ResultSetHeader>(query, values);
    
    if (result.affectedRows === 0) return null;
    
    return this.findById(id);
  }

  async delete(id: string): Promise<boolean> {
    const query = 'DELETE FROM students WHERE id = ?';
    const [result] = await pool.execute<ResultSetHeader>(query, [id]);
    
    return result.affectedRows > 0;
  }

  private mapRowToStudent(row: RowDataPacket): Student {
    return {
      id: row.id,
      Name: row.Name,
      Roll: row.Roll,
      Registration: row.Registration,
      Department: row.Department,
      Session: row.Session,
      ContactNumber: row.ContactNumber,
      Address: row.Address,
      qrCode: row.qrCode
    };
  }
}
