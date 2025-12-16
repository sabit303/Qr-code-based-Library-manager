import { Router } from "express";
import { BookController } from "../Controller/BookController.js";
import { BookServices } from "../Services/BookServices.js";
import { MySQLBookRepository } from "../Repositories/MySQLBookRepository.js";

const router = Router();

// Dependency Injection
const bookRepository = new MySQLBookRepository();
const bookService = new BookServices(bookRepository);
const bookController = new BookController(bookService);

// Public Book Routes (Read-only)
router.get("/", (req, res) => bookController.getAll(req, res));
router.get("/search", (req, res) => bookController.search(req, res));
router.get("/:id", (req, res) => bookController.getById(req, res));
export default router;
