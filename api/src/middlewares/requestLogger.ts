import { Request, Response, NextFunction } from 'express';

export const requestLogger = (req: Request, res: Response, next: NextFunction) => {
    const timestamp = new Date().toISOString();
    const method = req.method;
    const url = req.originalUrl;
    const ip = req.ip || req.socket.remoteAddress;

    console.log(`[${timestamp}] ${method} ${url} - IP: ${ip}`);

    const start = Date.now();

    res.on('finish', () => {
        const duration = Date.now() - start;
        const statusCode = res.statusCode;
        const statusColor = statusCode >= 500 ? '🔴' : statusCode >= 400 ? '🟡' : '🟢';
        
        console.log(`[${timestamp}] ${statusColor} ${method} ${url} - ${statusCode} - ${duration}ms`);
    });

    next();
};
