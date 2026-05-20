import { Request, Response, NextFunction } from "express";
import { AppError, ValidationError } from "../errors/AppError.js";

/**
 * Error response interface
 */
interface ErrorResponse {
  success: false;
  message: string;
  errorCode?: string;
  errors?: any[];
  stack?: string;
}

/**
 * Global error handling middleware
 * This should be the last middleware in the chain
 */
export const errorHandler = (
  err: Error | AppError,
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  // Log error for debugging
  console.error("Error occurred:", {
    name: err.name,
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  });

  // If headers already sent, delegate to default Express error handler
  if (res.headersSent) {
    return next(err);
  }

  // Handle AppError instances
  if (err instanceof AppError) {
    const response: ErrorResponse = {
      success: false,
      message: err.message,
      errorCode: err.errorCode,
    };

    // Include validation errors if present
    if (err instanceof ValidationError && err.errors) {
      response.errors = err.errors;
    }

    // Include stack trace in development
    if (process.env.NODE_ENV === "development") {
      response.stack = err.stack;
    }

    res.status(err.statusCode).json(response);
    return;
  }

  // Handle JWT errors
  if (err.name === "JsonWebTokenError") {
    res.status(401).json({
      success: false,
      message: "Invalid token",
      errorCode: "INVALID_TOKEN",
    });
    return;
  }

  if (err.name === "TokenExpiredError") {
    res.status(401).json({
      success: false,
      message: "Token expired",
      errorCode: "TOKEN_EXPIRED",
    });
    return;
  }

  // Handle MySQL/Database errors
  if (err.name === "ER_DUP_ENTRY" || (err as any).code === "ER_DUP_ENTRY") {
    res.status(409).json({
      success: false,
      message: "Duplicate entry. Resource already exists",
      errorCode: "DUPLICATE_ENTRY",
    });
    return;
  }

  if (err.name === "ER_NO_REFERENCED_ROW" || (err as any).code === "ER_NO_REFERENCED_ROW") {
    res.status(400).json({
      success: false,
      message: "Invalid reference. Related resource not found",
      errorCode: "INVALID_REFERENCE",
    });
    return;
  }

  // Handle validation errors from express-validator or similar
  if (err.name === "ValidationError") {
    res.status(422).json({
      success: false,
      message: err.message || "Validation failed",
      errorCode: "VALIDATION_ERROR",
    });
    return;
  }

  // Default to 500 Internal Server Error
  const response: ErrorResponse = {
    success: false,
    message: process.env.NODE_ENV === "development" 
      ? err.message 
      : "An unexpected error occurred",
    errorCode: "INTERNAL_ERROR",
  };

  if (process.env.NODE_ENV === "development") {
    response.stack = err.stack;
  }

  res.status(500).json(response);
};

/**
 * Handler for 404 Not Found
 * Use this before the error handler middleware
 */
export const notFoundHandler = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`,
    errorCode: "ROUTE_NOT_FOUND",
  });
};

/**
 * Async handler wrapper to catch errors in async route handlers
 * Usage: asyncHandler(async (req, res) => { ... })
 */
export const asyncHandler = (
  fn: (req: Request, res: Response, next: NextFunction) => Promise<any>
) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
