import { MySQLStudentRepository } from "../Repositories/MySQLStudentRepository.js";
import { PasswordHasher } from "../Helper/passHash.js";
import { Student } from "../Entities/Student.js";
import jwt from "jsonwebtoken";
import dotenv from 'dotenv';
import { LoggedInDTO } from "../DTOs/LoggedInDTO.js";
dotenv.config();



export class loginServices{
    constructor(
        private studentrepo: MySQLStudentRepository,
        private hashPass: PasswordHasher
    ){}
    async validateStudent(Id: string, password:string): Promise<LoggedInDTO|null>{
        try{
            const student: Student|null = await this.studentrepo.findById(Id);
            if(student != null && student.Password){
            const isValid: boolean =  await this.hashPass.verifyPassword(password,student.Password);
            if(isValid){ 
                const jwtSecret = process.env.jwt_secret;
                if (!jwtSecret) {
                    throw new Error("JWT secret is not defined in environment variables");
                }
                 let token = jwt.sign({
                name : student.Name,
                registration : student.Registration,
                roll : student.Roll,
                rule : student
            }, jwtSecret,{expiresIn:"1h"});
        
            return {
                token: token,
                success: true,
                msg: "Succcessfully Loged in",
                date: new Date().toISOString()
            }
        }


        }
        return{
            token: null,
            success: false,
            msg: "Wrong email or password",
            date: new Date().toISOString()
        }
        }catch(e){
            console.log(e);
            return null;
        }
    }

}