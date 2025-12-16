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
router.post("/", (req, res) => studentController.create(req, res));
router.get("/", (req, res) => studentController.getAll(req, res));
router.get("/:id", (req, res) => studentController.getById(req, res));
router.put("/:id", (req, res) => studentController.update(req, res));
router.delete("/:id", (req, res) => studentController.delete(req, res));
router.post("/:id/qrcode", (req, res) => studentController.generateQRCode(req, res));
router.get("/qrcode/:qrCode", (req, res) => studentController.getByQRCode(req, res));



export default router;
