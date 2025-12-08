import { RequestNewBookDTO } from "../DTOs/BookDTO.js";
import { Request, Response } from "express";
import { borrowService } from "../Services/BorrowServices.js";

export class BorrowController {
    constructor(private borrowService: borrowService) {}

    async requestNewBook(req: Request, res: Response): Promise<Response> {
        try {
            const dto: RequestNewBookDTO = req.body;
            const transaction = await this.borrowService.requestNewBook(dto);
            
            if (!transaction) {
                return res.status(400).json({
                    success: false,
                    message: "Failed to request book"
                });
            }

            return res.status(201).json({
                success: true,
                message: "Book request created successfully",
                data: transaction
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error requesting book",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

    async confirmBookRequest(req: Request, res: Response): Promise<Response> {
        try {
            const dto: RequestNewBookDTO = req.body;
            const transaction = await this.borrowService.confirmBookRequest(dto);
            
            if (!transaction) {
                return res.status(404).json({
                    success: false,
                    message: "Book request not found or already confirmed"
                });
            }

            return res.status(200).json({
                success: true,
                message: "Book issued successfully",
                data: transaction
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error confirming book request",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

    async returnBook(req: Request, res: Response): Promise<Response> {
        try {
            const dto: RequestNewBookDTO = req.body;
            const transaction = await this.borrowService.returnBook(dto);
            
            if (!transaction) {
                return res.status(404).json({
                    success: false,
                    message: "Transaction not found or already returned"
                });
            }

            return res.status(200).json({
                success: true,
                message: "Book returned successfully",
                data: transaction
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error returning book",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }
}