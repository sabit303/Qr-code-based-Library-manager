import { RequestNewBookDTO } from "../DTOs/BookDTO.js";
import { Request, Response } from "express";
import { borrowService } from "../Services/BorrowServices.js";
import { Transaction } from "../Entities/Transaction.js";

export class BorrowController {
    constructor(private borrowService: borrowService) {}

    async requestNewBook(req: Request, res: Response): Promise<Response> {
        try {
            const dto: RequestNewBookDTO = req.body;
            const Registration = req.user?.registration;
            const userRole = req.user?.role;
            console.log(req.user);
            if (!Registration || !userRole) {
                return res.status(401).json({
                    success: false,
                    message: "Unauthorized - User information missing"
                });
            }

            const transaction = await this.borrowService.requestNewBook(dto, Registration, userRole);
            console.log(transaction);
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

    async GetTransactions(req: Request, res:Response): Promise<Response>{
        try{
            const {status} = req.query;
            const userId = req.user?.id;
            const Registration = req.user?.registration;
            const userRole = req.user?.role;

            if (!userId || !userRole) {
                return res.status(401).json({
                    success: false,
                    message: "Unauthorized - User information missing"
                });
            }

            const transactions: Transaction[] | null = await this.borrowService.GetAllTransactionsByStatus(status as string, userId, userRole,Registration);
            console.log(transactions);
            if(!transactions){
                return res.status(400).json({
                    msg: "Invalid status",
                    date: new Date().toISOString()
                })
            }

            return res.status(200).json({
                success: true,
                data: transactions,
                date: new Date().toISOString()
            })
        }catch(error){
             return res.status(500).json({
                success: false,
                message: "Error Getting transactions data",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }

    async returnBook(req: Request, res: Response): Promise<Response> {
        try {
            const dto: RequestNewBookDTO = req.body;
            const userId = req.user?.id;
            const userRole = req.user?.role;

            if (!userId || !userRole) {
                return res.status(401).json({
                    success: false,
                    message: "Unauthorized - User information missing"
                });
            }

            const transaction = await this.borrowService.returnBook(dto, userId, userRole);
            
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

    async deleteRequest(req: Request, res: Response): Promise<Response> {
        try {
            const dto: RequestNewBookDTO = req.body;
            const userId = req.user?.id;
            const userRole = req.user?.role;

            if (!userId || !userRole) {
                return res.status(401).json({
                    success: false,
                    message: "Unauthorized - User information missing"
                });
            }

            const deleted = await this.borrowService.deleteRequest(dto, userId, userRole);
            
            if (!deleted) {
                return res.status(404).json({
                    success: false,
                    message: "Request not found or could not be deleted"
                });
            }

            return res.status(200).json({
                success: true,
                message: "Book request deleted successfully"
            });
        } catch (error) {
            return res.status(500).json({
                success: false,
                message: "Error deleting book request",
                error: error instanceof Error ? error.message : "Unknown error"
            });
        }
    }
}