import { Request,Response,NextFunction } from "express";
import { loginDTO } from "../DTOs/LoginDTO.js";
import { loginServices } from "../Services/LoginService.js";
import jwt from "jsonwebtoken";
import dotenv from 'dotenv';
dotenv.config();


export class authController{

        constructor(private LoginService: loginServices){}

    async login(req: Request, res: Response): Promise<Response> {
        const dto: loginDTO = req.body;
        const userType = req.body.role || 'student'; // Default to student if not specified
        
        const result = await this.LoginService.login(dto.email, dto.password, userType);

        if(result != null){
            return res.status(200).json(result);
        }
           
        return res.status(404).json({
            msg: "User Not Found"
        })
    }

}