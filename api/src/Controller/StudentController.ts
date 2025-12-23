import { Response, Request } from "express";
import { StudentService } from "../Services/StudentService.js";
import { CreateStudentDTO, UpdateStudentDTO } from "../DTOs/StudentDTO.js";

export class StudentController {
  constructor(private studentService: StudentService) {}

  async create(req: Request, res: Response): Promise<Response> {
    try {
      const dto: CreateStudentDTO = req.body;
      const student = await this.studentService.create(dto);
      return res.status(201).json({ 
        success: true,
        data: student, 
        message: "Student created successfully" 
      });
    } catch (error) {
      return res.status(500).json({ 
        success: false,
        message: "Error creating student", 
        error: error instanceof Error ? error.message : "Unknown error" 
      });
    }
  }

  async getAll(req: Request, res: Response): Promise<Response> {
    try {
      const { page = 1, limit = 10, search } = req.query;
      const result = await this.studentService.getAll({
        page: Number(page),
        limit: Number(limit),
        search: search as string
      });
      return res.status(200).json({ 
        success: true,
        data: result 
      });
    } catch (error) {
      return res.status(500).json({ 
        success: false,
        message: "Error fetching students", 
        error: error instanceof Error ? error.message : "Unknown error" 
      });
    }
  }

  async getById(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const student = await this.studentService.getById(id);
      
      if (!student) {
        return res.status(404).json({ 
          success: false,
          message: "Couldn't Find the student with the id" 
        });
      }

      return res.status(200).json({ 
        success: true,
        data: student 
      });
    } catch (error) {
      return res.status(500).json({ 
        success: false,
        message: "Error fetching student", 
        error: error instanceof Error ? error.message : "Unknown error" 
      });
    }
  }

  async update(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const dto: UpdateStudentDTO = req.body;
      const student = await this.studentService.update(id, dto);
      
      if (!student) {
        return res.status(404).json({ 
          success: false,
          message: "Student not found" 
        });
      }

      return res.status(200).json({ 
        success: true,
        data: student, 
        message: "Student updated successfully" 
      });
    } catch (error) {
      return res.status(500).json({ 
        success: false,
        message: "Error updating student", 
        error: error instanceof Error ? error.message : "Unknown error" 
      });
    }
  }

  async delete(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const deleted = await this.studentService.delete(id);
      
      if (!deleted) {
        return res.status(404).json({ 
          success: false,
          message: "Student not found" 
        });
      }

      return res.status(200).json({ 
        success: true,
        message: "Student deleted successfully" 
      });
    } catch (error) {
      return res.status(500).json({ 
        success: false,
        message: "Error deleting student", 
        error: error instanceof Error ? error.message : "Unknown error" 
      });
    }
  }

  async generateQRCode(req: Request, res: Response): Promise<Response> {
    try {
      const { id } = req.params;
      const qrCode = await this.studentService.generateQRCode(id);
      
      if (!qrCode) {
        return res.status(404).json({ 
          success: false,
          message: "Student not found" 
        });
      }

      return res.status(200).json({ 
        success: true,
        data: { qrCode },
        message: "QR code generated successfully"
      });
    } catch (error) {
      return res.status(500).json({ 
        success: false,
        message: "Error generating QR code", 
        error: error instanceof Error ? error.message : "Unknown error" 
      });
    }
  }

  async getByQRCode(req: Request, res: Response): Promise<Response> {
    try {
      const { qrCode } = req.params;
      const student = await this.studentService.getByQRCode(qrCode);
      
      if (!student) {
        return res.status(404).json({ 
          success: false,
          message: "Student not found" 
        });
      }

      return res.status(200).json({ 
        success: true,
        data: student 
      });
    } catch (error) {
      return res.status(500).json({ 
        success: false,
        message: "Error fetching student", 
        error: error instanceof Error ? error.message : "Unknown error" 
      });
    }
  }
}

