import { Request,Response } from "express";
import { loginDTO } from "../DTOs/LoginDTO.js";
import { loginServices } from "../Services/LoginService.js";


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
}