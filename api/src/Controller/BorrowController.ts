import { RequestNewBookDTO } from "../DTOs/BookDTO.js";
import { Request, Response, NextFunction } from "express";
import { borrowService } from "../Services/BorrowServices.js";
import { Transaction } from "../Entities/Transaction.js";
import { UnauthorizedError, NotFoundError, BadRequestError } from "../errors/AppError.js";
import { asyncHandler } from "../middlewares/errorHandler.js";

export class BorrowController {
    constructor(private borrowService: borrowService) {}

    requestNewBook = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const dto: RequestNewBookDTO = req.body;
        // For students, use registration; for librarians, use id
        const Registration = req.user?.registration || req.user?.id;
        const userRole = req.user?.role;
        
        if (!Registration || !userRole) {
            throw new UnauthorizedError("User information missing");
        }

        // The student must choose an expected return date when requesting a book.
        if (!dto.returnDate) {
            throw new BadRequestError("A return date is required to request a book");
        }

        const transaction = await this.borrowService.requestNewBook(dto, Registration, userRole);
        
        if (!transaction) {
            throw new BadRequestError("Failed to request book");
        }

        res.status(201).json({
            success: true,
            message: "Book request created successfully",
            data: transaction
        });
    });

    confirmBookRequest = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const dto: RequestNewBookDTO = req.body;
        const returnDate = req.body.returnDate;
        const transaction = await this.borrowService.confirmBookRequest(dto, returnDate);
        
        if (!transaction) {
            throw new NotFoundError("Book request not found or already confirmed");
        }

        res.status(200).json({
            success: true,
            message: "Book issued successfully",
            data: transaction
        });
    });

    GetTransactions = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const {status} = req.query;
        const userId = req.user?.id;
        const Registration = req.user?.registration;
        const userRole = req.user?.role;

        if (!userId || !userRole) {
            throw new UnauthorizedError("User information missing");
        }

        const transactions: Transaction[] | null = await this.borrowService.GetAllTransactionsByStatus(status as string, userId, userRole, Registration);
        
        if(!transactions){
            throw new BadRequestError("Invalid status");
        }

        res.status(200).json({
            success: true,
            data: transactions,
            date: new Date().toISOString()
        });
    });

    returnBook = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const dto: RequestNewBookDTO = req.body;
        const userId = req.user?.id;
        const userRole = req.user?.role;

        if (!userId || !userRole) {
            throw new UnauthorizedError("User information missing");
        }

        const transaction = await this.borrowService.returnBook(dto, userId, userRole);
        
        if (!transaction) {
            throw new NotFoundError("Transaction not found or already returned");
        }

        res.status(200).json({
            success: true,
            message: "Book returned successfully",
            data: transaction
        });
    });

    deleteRequest = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const dto: RequestNewBookDTO = req.body;
        const userId = req.user?.id;
        const userRole = req.user?.role;

        if (!userId || !userRole) {
            throw new UnauthorizedError("User information missing");
        }

        const deleted = await this.borrowService.deleteRequest(dto, userId, userRole);
        
        if (!deleted) {
            throw new NotFoundError("Request not found or could not be deleted");
        }

        res.status(200).json({
            success: true,
            message: "Book request deleted successfully"
        });
    });
}