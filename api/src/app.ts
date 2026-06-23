import express, { Application } from "express";
import studentRoutes from "./Routes/StudentRoutes.js";
import borrowRoutes from "./Routes/BorrowRoutes.js";
import bookRoutes from "./Routes/BookRoutes.js";
import librarianRoutes from "./Routes/LibrarianRoutes.js";
import authRoutes from "./Routes/AuthRoutes.js";
import { requestLogger } from "./middlewares/requestLogger.js";
import { errorHandler, notFoundHandler } from "./middlewares/errorHandler.js";

const app: Application = express();

// Custom CORS middleware to allow requests from Flutter Web
app.use((req, res, next) => {
  // Clear any existing CORS headers to prevent duplication
  res.removeHeader('Access-Control-Allow-Origin');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  res.setHeader('Access-Control-Max-Age', '3600');
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  next();
});

// Middleware
app.use(express.json({ limit: '7mb' }));
app.use(express.urlencoded({ limit: '7mb', extended: true }));
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

// 404 handler - must be after all routes
app.use(notFoundHandler);

// Global error handler - must be last
app.use(errorHandler);

export default app;
