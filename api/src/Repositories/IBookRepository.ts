import { promises } from "dns";
import { Book } from "../Entities/Book.js";

export interface IBookRepository{
        addNewBook(data: Partial<Book>): Promise<Book>;
        removeBook(Id: String): Promise<boolean>;
        displayBookInfo(Id: String): Promise<Book | null>;

}