import { MySQLBookRepository } from "../Repositories/MySQLBookRepository.js";
import { IBookRepository } from "../Repositories/IBookRepository.js";
import { privateDecrypt } from "crypto";


export class BookServices {
     constructor(
        private BookRepository: IBookRepository

     ){};

     addNewBook(){
        
     }
}