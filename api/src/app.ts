import express, { Application } from "express";
import studentRoutes from "./Routes/StudentRoutes.js";
import borrowRoutes from "./Routes/BorrowRoutes.js";
import bookRoutes from "./Routes/BookRoutes.js";
import librarianRoutes from "./Routes/LibrarianRoutes.js";
import authRoutes from "./Routes/AuthRoutes.js";
import { requestLogger } from "./middlewares/requestLogger.js";

const app: Application = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(requestLogger);

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/students", studentRoutes);
app.use("/api/borrow", borrowRoutes);
app.use("/api/books", bookRoutes);
app.use("/api/librarian", librarianRoutes);

// Health check
app.get("/health", (req, res) => {
  res.status(200).json({ status: "OK", message: "Server is running" });
});

export default app;
