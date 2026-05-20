import { BookServices } from "../Services/BookServices.js";
import { Response, Request, NextFunction } from "express";
import { AddNewBookDTO, UpdateBookDTO } from "../DTOs/BookDTO.js";
import { NotFoundError } from "../errors/AppError.js";
import { asyncHandler } from "../middlewares/errorHandler.js";

export class BookController {
    constructor(private bookService: BookServices) {}

    addNewBook = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const dto: AddNewBookDTO = req.body;

        // support base64 cover upload
        if ((req.body as any).coverBase64) {
            try {
                const { uploadImageToCloudflare } = await import('../utils/CloudflareImages.js');
                const base64 = (req.body as any).coverBase64 as string;
                const filename = `${dto.Name.replace(/\s+/g, '_')}_${Date.now()}.jpg`;
                const url = await uploadImageToCloudflare(base64, filename);
                dto.CoverUrl = url;
            } catch (e) {
                console.error('Cover upload failed:', e);
                dto.CoverUrl = null as any; // Set to null on error so book can still be created
            }
        }
        const newBook = await this.bookService.addNewBook(dto);
        res.status(201).json({
            success: true,
            data: newBook,
            message: "Book created successfully"
        });
    });

    updateBook = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const { id } = req.params;
        const dto: UpdateBookDTO = req.body;
        const book = await this.bookService.update(id, dto);
        
        if (!book) {
            throw new NotFoundError("Book not found");
        }

        res.status(200).json({
            success: true,
            data: book,
            message: "Book updated successfully"
        });
    });

    search = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const { query } = req.query;
        const books = await this.bookService.search(query as string);
        res.status(200).json({
            success: true,
            data: books
        });
    });

    getById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const { id } = req.params;
        const book = await this.bookService.getById(id);
        
        if (!book) {
            throw new NotFoundError("Book not found");
        }

        res.status(200).json({
            success: true,
            data: book
        });
    });

    getByQRCode = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const { qrCode } = req.params;
        const book = await this.bookService.getByQRCode(qrCode);
        
        if (!book) {
            throw new NotFoundError("Book not found");
        }

        res.status(200).json({
            success: true,
            data: book
        });
    });

    removeBook = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const { id } = req.params;
        const deleted = await this.bookService.removeBook(id);
        
        if (!deleted) {
            throw new NotFoundError("Book not found");
        }

        res.status(200).json({
            success: true,
            message: "Book deleted successfully"
        });
    });

    displayBookDetails = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const { id } = req.params;
        const book = await this.bookService.displayBookDetails(id);
        
        if (!book) {
            throw new NotFoundError("Book not found");
        }

        res.status(200).json({
            success: true,
            data: book
        });
    });

    getAll = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const { page = 1, limit = 50, search } = req.query;
        const result = await this.bookService.getAll({
            page: Number(page),
            limit: Number(limit),
            search: search as string
        });
        res.status(200).json({
            success: true,
            data: result
        });
    });
}
