import { Response, Request, NextFunction } from "express";
import { StudentService } from "../Services/StudentService.js";
import { CreateStudentDTO, UpdateStudentDTO } from "../DTOs/StudentDTO.js";
import { NotFoundError, ValidationError } from "../errors/AppError.js";
import { asyncHandler } from "../middlewares/errorHandler.js";

export class StudentController {
  constructor(private studentService: StudentService) {}

  create = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const dto: CreateStudentDTO = req.body;

    // If client sent a base64 photo (e.g., from camera), upload to Cloudflare
    if ((req.body as any).photoBase64) {
      try {
        console.log("📸 Attempting to upload student photo to Cloudflare R2...");
        const { uploadImageToCloudflare } = await import('../utils/CloudflareImages.js');
        const photoBase64 = (req.body as any).photoBase64 as string;
        const filename = `${dto.Registration || Date.now()}.jpg`;
        const url = await uploadImageToCloudflare(photoBase64, filename);
        dto.PhotoUrl = url;
        console.log("✅ Photo uploaded successfully:", url);
      } catch (e) {
        console.error('❌ Photo upload failed:', e);
        dto.PhotoUrl = null as any; // Set to null on error so student can still be created
      }
    }
    
    // Validate required fields - Roll, Registration and Name are mandatory.
    // All other details are optional and can be filled in by the student later.
    const requiredFields = ['Name', 'Roll', 'Registration'];
    const missingFields = requiredFields.filter(field => !dto[field as keyof CreateStudentDTO]);
    
    if (missingFields.length > 0) {
      throw new ValidationError(
        "Missing required fields", 
        missingFields.map(field => ({ field, message: `${field} is required` }))
      );
    }

    // Default the password to the student's registration number when not provided.
    // The student can change it later from their profile.
    if (!dto.Password) {
      dto.Password = dto.Registration;
    }
    
    const student = await this.studentService.create(dto);
    const { Password, ...studentWithoutPassword } = student;
    res.status(201).json({ 
      success: true,
      data: studentWithoutPassword, 
      message: "Student created successfully" 
    });
  });

  getAll = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { page = 1, limit = 50 } = req.query;
    const result = await this.studentService.getAll({
      page: Number(page),
      limit: Number(limit),
    });
    res.status(200).json({ 
      success: true,
      data: result 
    });
  });

  getById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params;
    const userId = req.user?.id;
    const userRole = req.user?.role;
    
    const student = await this.studentService.getById(id, userId, userRole);
    
    if (!student) {
      throw new NotFoundError("Student not found");
    }

    res.status(200).json({ 
      success: true,
      data: student 
    });
  });

  update = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params;
    const dto: UpdateStudentDTO = req.body;
    const userId = req.user?.id;
    const userRole = req.user?.role;

    // If client sent a base64 photo (e.g., from camera), upload to Cloudflare
    if ((req.body as any).photoBase64) {
      try {
        console.log("📸 Attempting to upload student photo to Cloudflare R2 (update)...");
        const { uploadImageToCloudflare } = await import('../utils/CloudflareImages.js');
        const photoBase64 = (req.body as any).photoBase64 as string;
        const filename = `${dto.Name || Date.now()}.jpg`;
        const url = await uploadImageToCloudflare(photoBase64, filename);
        dto.PhotoUrl = url;
        console.log("✅ Photo uploaded successfully (update):", url);
      } catch (e) {
        console.error('❌ Photo upload failed (update):', e);
        dto.PhotoUrl = undefined; // Don't update photo on error
      }
    }
    
    const student = await this.studentService.update(id, dto, userId, userRole);
    
    if (!student) {
      throw new NotFoundError("Student not found");
    }

    res.status(200).json({ 
      success: true,
      data: student, 
      message: "Student updated successfully" 
    });
  });

  delete = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params;
    const deleted = await this.studentService.delete(id);
    
    if (!deleted) {
      throw new NotFoundError("Student not found");
    }

    res.status(200).json({ 
      success: true,
      message: "Student deleted successfully" 
    });
  });

  generateQRCode = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { id } = req.params;
    const userId = req.user?.id;
    const userRole = req.user?.role;
    
    const qrCode = await this.studentService.generateQRCode(id, userId, userRole);
    
    if (!qrCode) {
      throw new NotFoundError("Student not found");
    }

    res.status(200).json({ 
      success: true,
      data: { qrCode },
      message: "QR code generated successfully"
    });
  });

  getByQRCode = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { qrCode } = req.params;
    const student = await this.studentService.getByQRCode(qrCode);
    
    if (!student) {
      throw new NotFoundError("Student not found");
    }

    res.status(200).json({ 
      success: true,
      data: student 
    });
  });

  getStudentWithHistory = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const { registration } = req.params;
    const data = await this.studentService.getStudentWithHistory(registration);
    
    if (!data) {
      throw new NotFoundError("Student not found");
    }

    res.status(200).json({ 
      success: true,
      data
    });
  });
}

