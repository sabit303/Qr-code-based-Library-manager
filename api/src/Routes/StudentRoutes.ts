import { Router } from "express";
import { StudentController } from "../Controller/StudentController.js";
import { StudentService } from "../Services/StudentService.js";
import { MySQLStudentRepository } from "../Repositories/MySQLStudentRepository.js";
import { QRCodeService } from "../Services/QRCodeService.js";

const router = Router();

// Dependency Injection - Following Dependency Inversion Principle
// Using MySQL repository instead of in-memory storage
const studentRepository = new MySQLStudentRepository();
const qrCodeService = new QRCodeService();
const studentService = new StudentService(studentRepository, qrCodeService);
const studentController = new StudentController(studentService);

// Routes
router.post("/students", (req, res) => studentController.create(req, res));
router.get("/students", (req, res) => studentController.getAll(req, res));
router.get("/students/:id", (req, res) => studentController.getById(req, res));
router.put("/students/:id", (req, res) => studentController.update(req, res));
router.delete("/students/:id", (req, res) => studentController.delete(req, res));
router.post("/students/:id/qrcode", (req, res) => studentController.generateQRCode(req, res));
router.get("/students/qrcode/:qrCode", (req, res) => studentController.getByQRCode(req, res));

export default router;
