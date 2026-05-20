import { Request,Response,NextFunction } from "express";
import { loginDTO } from "../DTOs/LoginDTO.js";
import { loginServices } from "../Services/LoginService.js";
import { UnauthorizedError } from "../errors/AppError.js";
import { asyncHandler } from "../middlewares/errorHandler.js";
import jwt from "jsonwebtoken";
import dotenv from 'dotenv';
dotenv.config();


export class authController{

        constructor(private LoginService: loginServices){}

    login = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const dto: loginDTO = req.body;
        const userType = req.body.role || 'student'; // Default to student if not specified
        
        const result = await this.LoginService.login(dto.email, dto.password, userType);

        if(result != null){
            res.status(200).json(result);
            return;
        }
           
        throw new UnauthorizedError("Invalid email or password");
    });

}