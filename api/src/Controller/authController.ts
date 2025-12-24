import { Request,Response,NextFunction } from "express";
import { loginDTO } from "../DTOs/LoginDTO.js";
import { loginServices } from "../Services/LoginService.js";
import jwt from "jsonwebtoken";
import dotenv from 'dotenv';
dotenv.config();


export class authController{

        constructor(private LoginService: loginServices){}

    async  login(req:Request,res: Response):Promise<Response> {
        const dto: loginDTO = req.body;
        const result = this.LoginService.validateStudent(dto.email, dto.password);

        if(result!=null){
            return res.status(200).json(result);
        }
           
            return res.status(404).json({
                msg: "User Not Exist"
            })
        
    }

    async auth(req: Request,res:Response,next: NextFunction){
        const token = req.headers.authorization?.split(" ")[1];

        try{
            if (!token || !process.env.jwt_secret) {
                return res.status(401).json({ msg: "Unauthorized" });
            }
            const decoded = jwt.verify(token, process.env.jwt_secret);
            next();
        } catch (error) {
            return res.status(401).json({ msg: "Invalid token" });
        }
    }
}