import { Router } from "express";
import { authController } from "../Controller/authController.js";
import { loginServices } from "../Services/LoginService.js";
import { MySQLStudentRepository } from "../Repositories/MySQLStudentRepository.js";
import { MySQLLibrarianRepository } from "../Repositories/MySQLLibrarianRepository.js";
import { PasswordHasher } from "../Helper/passHash.js";

const router = Router();

// Dependency Injection
const studentRepository = new MySQLStudentRepository();
const librarianRepository = new MySQLLibrarianRepository();
const passwordHasher = new PasswordHasher();
const loginService = new loginServices(studentRepository, librarianRepository, passwordHasher);
const authControllerInstance = new authController(loginService);

// Auth Routes (Public)
router.post("/login", (req, res) => authControllerInstance.login(req, res));

export default router;
