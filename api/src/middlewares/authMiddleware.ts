import jwt from "jsonwebtoken";
import { Request, Response, NextFunction } from "express";

export function authMiddleware(
  req: Request,
  res: Response,
  next: NextFunction
) {
  const token = req.headers.authorization?.split(" ")[1];

  if (!token || !process.env.JWT_SECRET) {
    return res.status(401).json({ msg: "Unauthorized" });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded as { id: string; email: string;registration: string;roll: string; role: string };
    next();
  } catch {
    return res.status(401).json({ msg: "Invalid token" });
  }
}
