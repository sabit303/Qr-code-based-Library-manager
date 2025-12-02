import { Response, Request } from "express";
import { AddNewBookDTO } from "../DTOs/BookDTO.js";
import { BookServices } from "../Services/BookServices.js";
import { Book } from "../Entities/Book.js";
import { time } from "console";


export class BookController{
     constructor(
        private Bookservice: BookServices
    ){};
    async newBook(req: Request, res: Response): Promise<Response>{
        try{
            const dto: AddNewBookDTO = req.body;
            const newBook = await this.Bookservice.addNewBook(dto);
            return res.status(201).json({
                Success: true,
                Book: newBook,
                Time: new Date().toISOString()
            })

        }catch(error){
           return res.status(500).json({
                Success: false,
                Eror: error instanceof Error ? error.message : "Unknown error" 
            })
        }
    }

    async removeBook(req:Request , res:Response): Promise<Response>{
        const {BookId} = req.params;
        try{
            const deletedBook = await this.Bookservice.removeBook(BookId);
            if(!deletedBook){
            return res.status(400).json({
                Success: false,
                Message:"Book not found"
            })}

            return res.status(200).json({
                Succes: true,
                Message: "Book deleted successfully"
            })

        }catch (error) {
                return res.status(500).json({ 
                success: false,
                message: "Error deleting Book", 
                error: error instanceof Error ? error.message : "Unknown error" 
            });
            }
    }


    async displayBookDetails(req: Request,res: Response): Promise<Response>{
      const { id } = req.params;
        try{
            const Book = await this.Bookservice.displayBookDetails(id);
            if (!Book) {
           return res.status(404).json({ 
            success: false,
            message: "Book not found" 
             });
            }

            return res.status(200).json({
                Success: true,
                Data: Book
            })

        }catch(error){
            return res.status(500).json({ 
            success: false,
            message: "Error fetching Book details", 
            error: error instanceof Error ? error.message : "Unknown error" 
            })
            }   
     }
}