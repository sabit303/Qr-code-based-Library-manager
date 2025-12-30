import { MySQLStudentRepository } from "../Repositories/MySQLStudentRepository.js";
import { MySQLLibrarianRepository } from "../Repositories/MySQLLibrarianRepository.js";
import { PasswordHasher } from "../Helper/passHash.js";
import { Student } from "../Entities/Student.js";
import { Librarian } from "../Entities/Librarian.js";
import jwt from "jsonwebtoken";
import dotenv from 'dotenv';
import { LoggedInDTO } from "../DTOs/LoggedInDTO.js";
dotenv.config();

export class loginServices{
    constructor(
        private studentRepo: MySQLStudentRepository,
        private librarianRepo: MySQLLibrarianRepository,
        private hashPass: PasswordHasher
    ){}

    async login(identifier: string, password: string, role: 'student' | 'librarian'): Promise<LoggedInDTO|null>{
        try{
            if (role === 'student') {
                return await this.validateStudent(identifier, password);
            } else {
                return await this.validateLibrarian(identifier, password);
            }
        } catch(e){
            console.log(e);
            return null;
        }
    }

    private async validateStudent(id: string, password: string): Promise<LoggedInDTO|null>{
        try{
            const student: Student|null = await this.studentRepo.findById(id, true);
            console.log(student);
            if(student != null && student.Password ){
                console.log("ok");
                const isValid: boolean = await this.hashPass.verifyPassword(password, student.Password);
                if(isValid){ 
                    const jwtSecret = process.env.JWT_SECRET;
                    if (!jwtSecret) {
                        throw new Error("JWT secret is not defined in environment variables");
                    }
                    let token = jwt.sign({
                        id: student.id,
                        name: student.Name,
                        registration: student.Registration,
                        roll: student.Roll,
                        role: 'student'
                    }, jwtSecret, {expiresIn: "1h"});
            
                    return {
                        token: token,
                        success: true,
                        msg: "Successfully Logged in",
                        date: new Date().toISOString()
                    }
                }
            }
            return{
                token: null,
                success: false,
                msg: "Wrong ID or password",
                date: new Date().toISOString()
            }
        }catch(e){
            console.log(e);
            return null;
        }
    }

    private async validateLibrarian(email: string, password: string): Promise<LoggedInDTO|null>{
        try{
            const librarian: Librarian|null = await this.librarianRepo.findByEmail(email);
            console.log(librarian);
            if(librarian != null && librarian.password){
                const isValid: boolean = await this.hashPass.verifyPassword(password, librarian.password);
                if(isValid){ 
                    const jwtSecret = process.env.JWT_SECRET;
                    console.log(jwtSecret);
                    if (!jwtSecret) {
                        throw new Error("JWT secret is not defined in environment variables");
                    }
                    let token = jwt.sign({
                        id: librarian.id,
                        name: librarian.name,
                        email: librarian.email,
                        role: 'librarian'
                    }, jwtSecret, {expiresIn: "1h"});
            
                    return {
                        token: token,
                        success: true,
                        msg: "Successfully Logged in",
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