import { Router } from "express";
import { StudentController } from "../Controller/StudentController.js";
import { StudentService } from "../Services/StudentService.js";
import { MySQLStudentRepository } from "../Repositories/MySQLStudentRepository.js";
import { MySQLTransactionRepository } from "../Repositories/MySQLBorrowRepository.js";
import { QRCodeService } from "../Services/QRCodeService.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { PasswordHasher } from "../Helper/passHash.js";
import { AuthorizeRole } from "../middlewares/authorizeRoleMiddleware.js";

const router = Router();

// Dependency Injection - Following Dependency Inversion Principle
// Using MySQL repository instead of in-memory storage
const studentRepository = new MySQLStudentRepository();
const borrowRepository = new MySQLTransactionRepository();
const qrCodeService = new QRCodeService();
const hashPass = new PasswordHasher();
const studentService = new StudentService(studentRepository, qrCodeService, hashPass, borrowRepository);
const studentController = new StudentController(studentService);
const roleAuthorizer = new AuthorizeRole();

// Routes
router.post("/", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res, next) => studentController.create(req, res, next));
router.get("/", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res, next) => studentController.getAll(req, res, next));
router.get("/:id", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res, next) => studentController.getById(req, res, next));
router.put("/:id", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res, next) => studentController.update(req, res, next));
router.delete("/:id", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res, next) => studentController.delete(req, res, next));
router.post("/:id/qrcode", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res, next) => studentController.generateQRCode(req, res, next));
router.get("/qrcode/:qrCode", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res, next) => studentController.getByQRCode(req, res, next));
router.get("/scan/:registration", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res, next) => studentController.getStudentWithHistory(req, res, next));



export default router;
