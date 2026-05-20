import { Router } from "express";
import { BookController } from "../Controller/BookController.js";
import { BookServices } from "../Services/BookServices.js";
import { MySQLBookRepository } from "../Repositories/MySQLBookRepository.js";
import { MySQLTransactionRepository } from "../Repositories/MySQLBorrowRepository.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { AuthorizeRole } from "../middlewares/authorizeRoleMiddleware.js";

const router = Router();

// Dependency Injection
const bookRepository = new MySQLBookRepository();
const borrowRepository = new MySQLTransactionRepository();
const bookService = new BookServices(bookRepository, borrowRepository);
const bookController = new BookController(bookService);
const roleAuthorizer = new AuthorizeRole();

// Book Management Routes
router.post("/", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res, next) => bookController.addNewBook(req, res, next));
router.put("/:id", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res, next) => bookController.updateBook(req, res, next));
router.delete("/:id", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res, next) => bookController.removeBook(req, res, next));

// Book View Routes
router.get("/", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res, next) => bookController.getAll(req, res, next));
router.get("/search", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res, next) => bookController.search(req, res, next));
router.get("/qr/:qrCode", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res, next) => bookController.getByQRCode(req, res, next));
router.get("/details/:id", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res, next) => bookController.displayBookDetails(req, res, next));
router.get("/availability/:id", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res, next) => bookController.getNextAvailableDate(req, res, next));
router.get("/:id", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res, next) => bookController.getById(req, res, next));

export default router;
