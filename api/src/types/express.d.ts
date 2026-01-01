declare global {
  namespace Express {
    interface Request {
      user?: {
        id: string;
        email: string;
        registration?:string;
        role?:string;
        role: string;
        iat?: number;
        exp?: number;
      };
    }
  }
}

export {};
