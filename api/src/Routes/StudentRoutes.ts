import { Router } from "express";
import { StudentController } from "../Controller/StudentController.js";
import { StudentService } from "../Services/StudentService.js";
import { MySQLStudentRepository } from "../Repositories/MySQLStudentRepository.js";
import { QRCodeService } from "../Services/QRCodeService.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { PasswordHasher } from "../Helper/passHash.js";
import { AuthorizeRole } from "../middlewares/authorizeRoleMiddleware.js";

const router = Router();

// Dependency Injection - Following Dependency Inversion Principle
// Using MySQL repository instead of in-memory storage
const studentRepository = new MySQLStudentRepository();
const qrCodeService = new QRCodeService();
const hashPass = new PasswordHasher();
const studentService = new StudentService(studentRepository, qrCodeService,hashPass);
const studentController = new StudentController(studentService);
const roleAuthorizer = new AuthorizeRole();

// Routes
router.post("/", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => studentController.create(req, res));
router.get("/", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => studentController.getAll(req, res));
router.get("/:id", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res) => studentController.getById(req, res));
router.put("/:id", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => studentController.update(req, res));
router.delete("/:id", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => studentController.delete(req, res));
router.post("/:id/qrcode", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => studentController.generateQRCode(req, res));
router.get("/qrcode/:qrCode", authMiddleware, roleAuthorizer.canAccess("librarian", "student"), (req, res) => studentController.getByQRCode(req, res));



export default router;
