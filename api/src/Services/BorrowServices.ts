import { Transaction } from "../Entities/Transaction.js";
import { MySQLTransactionRepository } from "../Repositories/MySQLBorrowRepository.js";
import { RequestNewBookDTO } from "../DTOs/BookDTO.js";
import { StudentService } from "./StudentService.js";
import { BookServices } from "./BookServices.js";
import { ForbiddenError, NotFoundError, ConflictError, BadRequestError } from "../errors/AppError.js";

export class borrowService {
  constructor(
    private transactionRepo: MySQLTransactionRepository,
    private studentservice: StudentService,
    private bookservice: BookServices
  ) { }


  async requestNewBook(dto: RequestNewBookDTO, userId: string, userRole: string): Promise<Partial<Transaction> | null> {
    try {
      // Ownership check: users can only request books for themselves
      if (userRole === 'student') {
        if (dto.StudentReg !== userId) {
          throw new ForbiddenError("You can only request books for yourself");
        }
      }
      const student = await this.studentservice.getById(dto.StudentReg);
      const book = await this.bookservice.getById(dto.bookID);
      if (!student || !book) {
        throw new NotFoundError("Book or Student not exist");
      }

      // Prevent duplicate requests or if already issued to the student
      const existingRequested = await this.transactionRepo.GetAllTransactionsByStatus("REQUESTED", dto.StudentReg, dto.bookID);
      if (existingRequested.length > 0) {
        throw new ConflictError("Already have a Request for same Book");
      }
      const existingIssued = await this.transactionRepo.GetAllTransactionsByStatus("ISSUED", dto.StudentReg, dto.bookID);
      if (existingIssued.length > 0) {
        throw new ConflictError("Student already has this book issued");
      }

      const transactionDetails = await this.transactionRepo.RequestANewBook(dto.bookID, dto.StudentReg);
      return transactionDetails;
    } catch (e) {
      console.log(e);
      throw e;
    }
  }

  async confirmBookRequest(dto: RequestNewBookDTO, returnDate?: string): Promise<Partial<Transaction> | null> {
    try {
      const student = await this.studentservice.getById(dto.StudentReg);
      const book = await this.bookservice.getById(dto.bookID);
      if (!student || !book) {
        throw new NotFoundError("Book or Student not exist");
      }

      // Prevent approving if student already has this book
      const existingIssued = await this.transactionRepo.GetAllTransactionsByStatus("ISSUED", dto.StudentReg, dto.bookID);
      if (existingIssued.length > 0) {
        throw new ConflictError("Student already has this book issued");
      }

      // Ensure copies available
      if ((book as any).availableCopies === 0 || (book as any).availableCopies <= 0) {
        throw new ConflictError("No copies available to issue");
      }

      const transactionDetails = await this.transactionRepo.ConfirmRequestForBook(dto.bookID, dto.StudentReg, returnDate);
      return transactionDetails;
    } catch (e) {
      console.log(e);
      throw e;
    }
  }
  async GetAllTransactionsByStatus(status: string, userId: string, userRole: string, Registration?: string): Promise<Transaction[] | null> {
    try {
      if (status === 'ISSUED' || status === 'RETURNED' || status === 'OVERDUE' || status === 'REQUESTED') {
        const transactions: Transaction[] = await this.transactionRepo.GetAllTransactionsByStatus(status);
        //console.log(transactions);
        // Ownership check: filter transactions by user
        if (userRole === "student") return transactions.filter(t => t.studentReg === Registration);
        return transactions;
      }
      throw new BadRequestError("Status not valid");
    } catch (e) {
      console.log(e);
      throw e;
    }
  }
  async returnBook(dto: RequestNewBookDTO, userId: string, userRole: string): Promise<Partial<Transaction> | null> {
    try {
      // Ownership check: students can only return their own books, librarians can return any book
      if (userRole === 'student' && dto.StudentReg !== userId) {
        throw new ForbiddenError("You can only return your own books");
      }

      const student = await this.studentservice.getById(dto.StudentReg);
      const book = await this.bookservice.getById(dto.bookID);

      if (student && book) {
        const transactionDetails = await this.transactionRepo.ReturnBorrowedBook(dto.bookID, dto.StudentReg);
        return transactionDetails;
      } else {
        throw new NotFoundError("Book or Student not exist");
      }
    } catch (e) {
      throw e;
    }
  }

  async deleteRequest(dto: RequestNewBookDTO, userId: string, userRole: string): Promise<boolean> {
    try {
      // Ownership check: users can only delete their own requests
      if (userRole === 'student' && dto.StudentReg !== userId) {
        throw new ForbiddenError("You can only delete your own requests");
      }

      // Check if student and book exist
      if (this.studentservice.getById(dto.StudentReg) != null && this.bookservice.getById(dto.bookID) != null) {
        // Verify the request exists and is in REQUESTED status
        const existingRequest = await this.transactionRepo.GetAllTransactionsByStatus("REQUESTED", dto.StudentReg, dto.bookID);

        if (existingRequest.length === 0) {
          throw new NotFoundError("No pending request found for this book");
        }

        const deleted = await this.transactionRepo.DeleteRequest(dto.bookID, dto.StudentReg);
        return deleted;
      } else {
        throw new NotFoundError("Book or Student not exist");
      }
    } catch (e) {
      console.log(e);
      throw e;
    }
  }
}
