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

        

        async requestNewBook(dto: RequestNewBookDTO): Promise<Partial<Transaction>|null>{
            try{
              if(this.studentservice.getById(dto.StudentReg) != null && !this.bookservice.getById(dto.bookID) != null){
                
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
              if(!this.studentservice.getById(dto.StudentReg) && !this.bookservice.getById(dto.bookID)){
                    const transactionDetails = this.transactionRepo.ConfirmRequestForBook(dto.bookID,dto.StudentReg);
                    return transactionDetails;
              }else{
                throw new Error("Book or Student not exist");
              }
            }catch(e){
                return null;
            }  
        }

        async returnBook(dto: RequestNewBookDTO): Promise<Partial<Transaction>|null>{
           try{
              if(!this.studentservice.getById(dto.StudentReg) && !this.bookservice.getById(dto.bookID)){
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