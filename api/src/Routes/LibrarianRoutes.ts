import { Router } from "express";
import { LibrarianController } from "../Controller/LibrarianController.js";
import { BookServices } from "../Services/BookServices.js";
import { MySQLBookRepository } from "../Repositories/MySQLBookRepository.js";

const router = Router();

// Dependency Injection
const bookRepository = new MySQLBookRepository();
const bookService = new BookServices(bookRepository);
const librarianController = new LibrarianController(bookService);

// Librarian Book Management Routes (Admin only)
router.post("/librarian/books", (req, res) => librarianController.addNewBook(req, res));
router.put("/librarian/books/:id", (req, res) => librarianController.updateBook(req, res));
router.delete("/librarian/books/:id", (req, res) => librarianController.removeBook(req, res));

// Librarian View Routes
router.get("/librarian/books", (req, res) => librarianController.getAll(req, res));
router.get("/librarian/books/:id", (req, res) => librarianController.getById(req, res));
router.get("/librarian/books/details/:id", (req, res) => librarianController.displayBookDetails(req, res));



export default router;