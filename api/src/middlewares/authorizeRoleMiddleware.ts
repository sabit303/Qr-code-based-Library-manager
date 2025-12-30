import { Request, Response, NextFunction } from "express";

export class AuthorizeRole {
  canAccess(...allowedRoles: string[]) {
    return (req: Request, res: Response, next: NextFunction) => {
      
      // 1️⃣ Must be authenticated first
      if (!req.user) {
        return res.status(401).json({
          msg: "Unauthenticated"
        });
      }

      // 2️⃣ Role check
      if (!allowedRoles.includes(req.user.role)) {
        return res.status(403).json({
          msg: "Forbidden role"
        });
      }

      // 3️⃣ Allowed
      next();
    };
  }
}
