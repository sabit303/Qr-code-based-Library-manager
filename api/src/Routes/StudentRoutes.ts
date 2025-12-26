import { Router } from "express";
import { StudentController } from "../Controller/StudentController.js";
import { StudentService } from "../Services/StudentService.js";
import { MySQLStudentRepository } from "../Repositories/MySQLStudentRepository.js";
import { QRCodeService } from "../Services/QRCodeService.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { PasswordHasher } from "../Helper/passHash.js";

const router = Router();

// Dependency Injection - Following Dependency Inversion Principle
// Using MySQL repository instead of in-memory storage
const studentRepository = new MySQLStudentRepository();
const qrCodeService = new QRCodeService();
const hashPass = new PasswordHasher();
const studentService = new StudentService(studentRepository, qrCodeService,hashPass);
const studentController = new StudentController(studentService);

// Routes
router.post("/", authMiddleware, (req, res) => studentController.create(req, res));
router.get("/", authMiddleware, (req, res) => studentController.getAll(req, res));
router.get("/:id", authMiddleware, (req, res) => studentController.getById(req, res));
router.put("/:id", authMiddleware, (req, res) => studentController.update(req, res));
router.delete("/:id", authMiddleware, (req, res) => studentController.delete(req, res));
router.post("/:id/qrcode", authMiddleware, (req, res) => studentController.generateQRCode(req, res));
router.get("/qrcode/:qrCode", authMiddleware, (req, res) => studentController.getByQRCode(req, res));



export default router;
