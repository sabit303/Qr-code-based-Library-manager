import { BookServices } from "../Services/BookServices.js";
import { Response, Request } from "express";
import { AddNewBookDTO, UpdateBookDTO } from "../DTOs/BookDTO.js";

export class BookController {
    constructor(private bookService: BookServices) {}

    async addNewBook(req: Request, res: Response): Promise<Response> {
        try {
            const dto: AddNewBookDTO = req.body;
            const newBook = await this.bookService.addNewBook(dto);
            return res.status(201).json({
                success: true,
                data: newBook,
                message: "Book created successfully"
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error creating book",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

    async updateBook(req: Request, res: Response): Promise<Response> {
        try {
            const { id } = req.params;
            const dto: UpdateBookDTO = req.body;
            const book = await this.bookService.update(id, dto);
            
            if (!book) {
                return res.status(404).json({
                    success: false,
                    message: "Book not found"
                });
            }

            return res.status(200).json({
                success: true,
                data: book,
                message: "Book updated successfully"
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error updating book",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

    async search(req: Request, res: Response): Promise<Response> {
        try {
            const { query } = req.query;
            const books = await this.bookService.search(query as string);
            return res.status(200).json({
                success: true,
                data: books
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error searching books",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }
    async getById(req: Request, res: Response): Promise<Response> {
        try {
            const { id } = req.params;
            const book = await this.bookService.getById(id);
            
            if (!book) {
                return res.status(404).json({
                    success: false,
                    message: "Book not found"
                });
            }

            return res.status(200).json({
                success: true,
                data: book
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error fetching book",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

    async getByQRCode(req: Request, res: Response): Promise<Response> {
        try {
            const { qrCode } = req.params;
            const book = await this.bookService.getByQRCode(qrCode);
            
            if (!book) {
                return res.status(404).json({
                    success: false,
                    message: "Book not found"
                });
            }

            return res.status(200).json({
                success: true,
                data: book
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error fetching book",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

    async removeBook(req: Request, res: Response): Promise<Response> {
        try {
            const { id } = req.params;
            const deleted = await this.bookService.removeBook(id);
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: "Book not found"
                });
            }

            return res.status(200).json({
                success: true,
                message: "Book deleted successfully"
            });
        } catch (error) {
            return res.status(500).json({ 
                success: false,
                message: "Error deleting book", 
                error: error instanceof Error ? error.message : "Unknown error" 
            });
        }
    }

    async displayBookDetails(req: Request, res: Response): Promise<Response> {
        try {
            const { id } = req.params;
            const book = await this.bookService.displayBookDetails(id);
            
            if (!book) {
                return res.status(404).json({ 
                    success: false,
                    message: "Book not found" 
                });
            }

            return res.status(200).json({
                success: true,
                data: book
            });
        } catch (error) {
            return res.status(500).json({ 
                success: false,
                message: "Error fetching book details", 
                error: error instanceof Error ? error.message : "Unknown error" 
            });
        }   
    }

    async getAll(req: Request, res: Response): Promise<Response> {
        try {
            const { page = 1, limit = 10, search } = req.query;
            const result = await this.bookService.getAll({
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
                message: "Error fetching books",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

}
