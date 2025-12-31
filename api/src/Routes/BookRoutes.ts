import { Router } from "express";
import { BookController } from "../Controller/BookController.js";
import { BookServices } from "../Services/BookServices.js";
import { MySQLBookRepository } from "../Repositories/MySQLBookRepository.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { AuthorizeRole } from "../middlewares/authorizeRoleMiddleware.js";

const router = Router();

// Dependency Injection
const bookRepository = new MySQLBookRepository();
const bookService = new BookServices(bookRepository);
const bookController = new BookController(bookService);
const roleAuthorizer = new AuthorizeRole();

// Book Management Routes
router.post("/", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => bookController.addNewBook(req, res));
router.put("/:id", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => bookController.updateBook(req, res));
router.delete("/:id", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => bookController.removeBook(req, res));

// Book View Routes
router.get("/", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res) => bookController.getAll(req, res));
router.get("/search", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res) => bookController.search(req, res));
router.get("/qr/:qrCode", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res) => bookController.getByQRCode(req, res));
router.get("/details/:id", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res) => bookController.displayBookDetails(req, res));
router.get("/:id", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res) => bookController.getById(req, res));

export default router;
