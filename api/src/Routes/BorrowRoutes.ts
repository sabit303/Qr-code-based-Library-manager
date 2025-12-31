import { Router } from "express";
import { BorrowController } from "../Controller/BorrowController.js";
import { borrowService } from "../Services/BorrowServices.js";
import { MySQLTransactionRepository } from "../Repositories/MySQLBorrowRepository.js";
import { StudentService } from "../Services/StudentService.js";
import { BookServices } from "../Services/BookServices.js";
import { MySQLStudentRepository } from "../Repositories/MySQLStudentRepository.js";
import { MySQLBookRepository } from "../Repositories/MySQLBookRepository.js";
import { QRCodeService } from "../Services/QRCodeService.js";
import { PasswordHasher } from "../Helper/passHash.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { AuthorizeRole } from "../middlewares/authorizeRoleMiddleware.js";

const router = Router();

const studentRepository = new MySQLStudentRepository();
const bookRepository = new MySQLBookRepository();
const transactionRepository = new MySQLTransactionRepository();
const qrCodeService = new QRCodeService();
const passwordHasher = new PasswordHasher();

const studentService = new StudentService(studentRepository,qrCodeService,passwordHasher);
const bookService = new BookServices(bookRepository);
const borrowServiceInstance = new borrowService(transactionRepository, studentService, bookService);

const borrowController = new BorrowController(borrowServiceInstance);
const roleAuthorizer = new AuthorizeRole();

router.post("/request", authMiddleware, roleAuthorizer.canAccess("student"), (req, res) => borrowController.requestNewBook(req, res));
router.patch("/confirm", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => borrowController.confirmBookRequest(req, res));
router.get("/transactions", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res) => borrowController.GetTransactions(req, res));
router.patch("/return", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => borrowController.returnBook(req, res));

export default router;
