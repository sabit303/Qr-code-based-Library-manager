import { Router } from "express";
import { LibrarianController } from "../Controller/LibrarianController.js";
import { LibrarianService } from "../Services/LibrarianService.js";
import { MySQLLibrarianRepository } from "../Repositories/MySQLLibrarianRepository.js";
import { PasswordHasher } from "../Helper/passHash.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { AuthorizeRole } from "../middlewares/authorizeRoleMiddleware.js";

const router = Router();

// Dependency Injection
const librarianRepository = new MySQLLibrarianRepository();
const passwordHasher = new PasswordHasher();
const librarianService = new LibrarianService(librarianRepository, passwordHasher);
const librarianController = new LibrarianController(librarianService);
const roleAuthorizer = new AuthorizeRole();

// Librarian Management Routes (Admin only)
router.post("/", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => librarianController.create(req, res));
router.get("/", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => librarianController.getAll(req, res));
router.get("/:id", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => librarianController.getById(req, res));
router.put("/:id", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => librarianController.update(req, res));
router.delete("/:id", authMiddleware, roleAuthorizer.canAccess("librarian"), (req, res) => librarianController.delete(req, res));

export default router;