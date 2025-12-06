import { privateDecrypt } from "crypto";
import { BookServices } from "../Services/BookServices.js";
import { Response, Request } from "express";



export class BookController{
    constructor(
    private bookService: BookServices
    ){}

    async search(req: Request, res: Response): Promise<Response> {
        try {
            const { q } = req.query;
            const books = await this.bookService.search(q as string);
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
