import { Request, Response, NextFunction } from "express";
import { UnauthorizedError, ForbiddenError } from "../errors/AppError.js";

export class AuthorizeRole {
  canAccess(...allowedRoles: string[]) {
    return (req: Request, res: Response, next: NextFunction) => {
      
      // 1️⃣ Must be authenticated first
      if (!req.user) {
        throw new UnauthorizedError("Authentication required");
      }

      // 2️⃣ Role check
      if (!req.user.role || !allowedRoles.includes(req.user.role)) {
        throw new ForbiddenError(`Access denied. Required roles: ${allowedRoles.join(', ')}`);
      }

      // 3️⃣ Allowed
      next();
    };
  }
}
