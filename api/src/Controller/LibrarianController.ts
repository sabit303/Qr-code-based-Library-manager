import { Response, Request } from "express";
import { LibrarianService } from "../Services/LibrarianService.js";
import { CreateLibrarianDTO, UpdateLibrarianDTO } from "../DTOs/LibrarianDTO.js";

export class LibrarianController {
    constructor(private librarianService: LibrarianService) {}

    async create(req: Request, res: Response): Promise<Response> {
        try {
            const dto: CreateLibrarianDTO = req.body;
            const librarian = await this.librarianService.create(dto);
            const { password, ...librarianWithoutPassword } = librarian;
            return res.status(201).json({
                success: true,
                data: librarianWithoutPassword,
                message: "Librarian created successfully"
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error creating librarian",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

    async getAll(req: Request, res: Response): Promise<Response> {
        try {
            const { page = 1, limit = 10, search } = req.query;
            const result = await this.librarianService.getAll({
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
                message: "Error fetching librarians",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

    async getById(req: Request, res: Response): Promise<Response> {
        try {
            const { id } = req.params;
            const userId = req.user?.id;
            const userRole = req.user?.role;
            
            const librarian = await this.librarianService.getById(id, userId, userRole);
            
            if (!librarian) {
                return res.status(404).json({
                    success: false,
                    message: "Librarian not found"
                });
            }

            return res.status(200).json({
                success: true,
                data: librarian
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error fetching librarian",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

    async update(req: Request, res: Response): Promise<Response> {
        try {
            const { id } = req.params;
            const dto: UpdateLibrarianDTO = req.body;
            const userId = req.user?.id;
            const userRole = req.user?.role;
            
            const librarian = await this.librarianService.update(id, dto, userId, userRole);
            
            if (!librarian) {
                return res.status(404).json({
                    success: false,
                    message: "Librarian not found"
                });
            }

            return res.status(200).json({
                success: true,
                data: librarian,
                message: "Librarian updated successfully"
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error updating librarian",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

    async delete(req: Request, res: Response): Promise<Response> {
        try {
            const { id } = req.params;
            const deleted = await this.librarianService.delete(id);
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: "Librarian not found"
                });
            }

            return res.status(200).json({
                success: true,
                message: "Librarian deleted successfully"
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error deleting librarian",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }
}