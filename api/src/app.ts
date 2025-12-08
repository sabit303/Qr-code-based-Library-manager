import express, { Application } from "express";
import studentRoutes from "./Routes/StudentRoutes.js";
import borrowRoutes from "./Routes/BorrowRoutes.js";

const app: Application = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routes
app.use("/api/students", studentRoutes);
app.use("/api/borrow", borrowRoutes);

// Health check
app.get("/health", (req, res) => {
  res.status(200).json({ status: "OK", message: "Server is running" });
});

export default app;
