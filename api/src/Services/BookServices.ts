import { MySQLBookRepository } from "../Repositories/MySQLBookRepository.js";
import { IBookRepository } from "../Repositories/IBookRepository.js";
import { privateDecrypt } from "crypto";
import { AddNewBookDTO } from "../DTOs/BookDTO.js";
import { promises } from "dns";
import { Book } from "../Entities/Book.js";


export class BookServices {
     constructor(
        private BookRepository: IBookRepository

     ){};

     async addNewBook(dto: AddNewBookDTO): Promise<Book>{
        const Book = await this.BookRepository.addNewBook(dto);
        return Book;
     }

     async removeBook(Id: string): Promise<boolean>{
      return this.BookRepository.removeBook(Id);
     }

     async displayBookDetails(Id: string): Promise<Book | null>{
         const Book = await this.BookRepository.displayBookInfo(Id);
         return Book;
     }
}