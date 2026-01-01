import { Transaction } from "../Entities/Transaction.js";
import { MySQLTransactionRepository } from "../Repositories/MySQLBorrowRepository.js";
import { RequestNewBookDTO } from "../DTOs/BookDTO.js";
import { StudentService } from "./StudentService.js";
import { BookServices } from "./BookServices.js";
import { error } from "console";

export class borrowService{
    constructor(
        private transactionRepo : MySQLTransactionRepository,
        private studentservice: StudentService,
        private bookservice: BookServices
    ){}

        

        async requestNewBook(dto: RequestNewBookDTO, userId: string, userRole: string): Promise<Partial<Transaction>|null>{
            try{
              // Ownership check: users can only request books for themselves
              if(userRole === 'student'){
              if (dto.StudentReg !== userId) {
                throw new Error("You can only request books for yourself");
              }
            }
              if(this.studentservice.getById(dto.StudentReg) != null && !this.bookservice.getById(dto.bookID) != null){
                const ifRequestedTheSameBook = await this.transactionRepo.GetAllTransactionsByStatus("REQUESTED",dto.StudentReg,dto.bookID);
                console.log(ifRequestedTheSameBook);
                if( ifRequestedTheSameBook.length != 0  ){throw new Error("Already have a Request for same Book")}
                    const transactionDetails = this.transactionRepo.RequestANewBook(dto.bookID,dto.StudentReg);
                    console.log(transactionDetails);
                    return transactionDetails;
              }else{
                throw new Error("Book or Student not exist");
              }
            }catch(e){
                console.log(e);
                return null;
            }
        }
      
        async confirmBookRequest(dto: RequestNewBookDTO): Promise<Partial<Transaction>|null>{
            try{
              if(this.studentservice.getById(dto.StudentReg) !=null && this.bookservice.getById(dto.bookID) !=null){
                    const transactionDetails = this.transactionRepo.ConfirmRequestForBook(dto.bookID,dto.StudentReg);
                    return transactionDetails;
              }else{
                throw new Error("Book or Student not exist");
              }
            }catch(e){
              console.log(e);
                return null;
            }  
        }
       async GetAllTransactionsByStatus(status:string, userId: string, userRole: string): Promise<Transaction []|null>{
            try{
              if (status === 'ISSUED' || status === 'RETURNED' || status === 'OVERDUE' || status === 'REQUESTED') {
                const transactions: Transaction[] = await this.transactionRepo.GetAllTransactionsByStatus(status);
                
                // Ownership check: filter transactions by user
                return transactions.filter(t => t.studentReg === userId);
              }
              throw new Error("Status not valid");
            } catch(e) {
              console.log(e);
              return null;
            }
       } 
        async returnBook(dto: RequestNewBookDTO, userId: string, userRole: string): Promise<Partial<Transaction>|null>{
           try{
              // Ownership check: users can only return their own books
              if (dto.StudentReg !== userId) {
                throw new Error("You can only return your own books");
              }

              if(this.studentservice.getById(dto.StudentReg) != null && this.bookservice.getById(dto.bookID) != null){
                    const transactionDetails = this.transactionRepo.ReturnBorrowedBook(dto.bookID,dto.StudentReg);
                    return transactionDetails;
              }else{
                throw new Error("Book or Student not exist");
              }
            }catch(e){
                return null;
            }
        }
}