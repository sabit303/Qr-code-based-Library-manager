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
router.post("/", authMiddleware,  roleAuthorizer.canAccess("librarian"), (req, res) => bookController.addNewBook(req, res));
router.put("/:id", authMiddleware, (req, res) => bookController.updateBook(req, res));
router.delete("/:id", authMiddleware, (req, res) => bookController.removeBook(req, res));

// Book View Routes
router.get("/", authMiddleware, (req, res) => bookController.getAll(req, res));
router.get("/search", authMiddleware, (req, res) => bookController.search(req, res));
router.get("/qr/:qrCode", authMiddleware, (req, res) => bookController.getByQRCode(req, res));
router.get("/details/:id", authMiddleware, (req, res) => bookController.displayBookDetails(req, res));
router.get("/:id", authMiddleware, (req, res) => bookController.getById(req, res));

export default router;
