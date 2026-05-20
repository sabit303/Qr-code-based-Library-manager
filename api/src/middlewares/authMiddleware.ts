import jwt from "jsonwebtoken";
import { Request, Response, NextFunction } from "express";
import { UnauthorizedError } from "../errors/AppError.js";

export function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
) {
  const token = req.headers.authorization?.split(" ")[1];

  if (!token) {
    throw new UnauthorizedError("No token provided");
  }

  if (!process.env.JWT_SECRET) {
    throw new Error("JWT_SECRET is not configured");
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded as { id: string; email: string;registration: string;roll: string; role: string };
    next();
  } catch (error) {
    throw new UnauthorizedError("Invalid or expired token");
  }
}
