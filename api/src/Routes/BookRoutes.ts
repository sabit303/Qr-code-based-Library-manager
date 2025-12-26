import { Router } from "express";
import { BookController } from "../Controller/BookController.js";
import { BookServices } from "../Services/BookServices.js";
import { MySQLBookRepository } from "../Repositories/MySQLBookRepository.js";

const router = Router();

// Dependency Injection
const bookRepository = new MySQLBookRepository();
const bookService = new BookServices(bookRepository);
const bookController = new BookController(bookService);

// Book Management Routes
router.post("/", (req, res) => bookController.addNewBook(req, res));
router.put("/:id", (req, res) => bookController.updateBook(req, res));
router.delete("/:id", (req, res) => bookController.removeBook(req, res));

// Book View Routes
router.get("/", (req, res) => bookController.getAll(req, res));
router.get("/search", (req, res) => bookController.search(req, res));
router.get("/qr/:qrCode", (req, res) => bookController.getByQRCode(req, res));
router.get("/details/:id", (req, res) => bookController.displayBookDetails(req, res));
router.get("/:id", (req, res) => bookController.getById(req, res));

export default router;
