import { Response, Request, NextFunction } from "express";
import { LibrarianService } from "../Services/LibrarianService.js";
import { CreateLibrarianDTO, UpdateLibrarianDTO } from "../DTOs/LibrarianDTO.js";
import { NotFoundError } from "../errors/AppError.js";
import { asyncHandler } from "../middlewares/errorHandler.js";

export class LibrarianController {
    constructor(private librarianService: LibrarianService) {}

    create = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const dto: CreateLibrarianDTO = req.body;
        const librarian = await this.librarianService.create(dto);
        const { password, ...librarianWithoutPassword } = librarian;
        res.status(201).json({
            success: true,
            data: librarianWithoutPassword,
            message: "Librarian created successfully"
        });
    });

    getAll = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const { page = 1, limit = 10, search } = req.query;
        const result = await this.librarianService.getAll({
            page: Number(page),
            limit: Number(limit),
            search: search as string
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
        
        const librarian = await this.librarianService.getById(id, userId, userRole);
        
        if (!librarian) {
            throw new NotFoundError("Librarian not found");
        }

        res.status(200).json({
            success: true,
            data: librarian
        });
    });

    update = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const { id } = req.params;
        const dto: UpdateLibrarianDTO = req.body;
        const userId = req.user?.id;
        const userRole = req.user?.role;
        
        const librarian = await this.librarianService.update(id, dto, userId, userRole);
        
        if (!librarian) {
            throw new NotFoundError("Librarian not found");
        }

        res.status(200).json({
            success: true,
            data: librarian,
            message: "Librarian updated successfully"
        });
    });

    delete = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const { id } = req.params;
        const deleted = await this.librarianService.delete(id);
        
        if (!deleted) {
            throw new NotFoundError("Librarian not found");
        }

        res.status(200).json({
            success: true,
            message: "Librarian deleted successfully"
        });
    });
}