/**
 * Base Application Error Class
 * All custom errors should extend this class
 */
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;
  public readonly errorCode?: string;

  constructor(
    message: string,
    statusCode: number = 500,
    isOperational: boolean = true,
    errorCode?: string
  ) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    this.errorCode = errorCode;

    // Maintains proper stack trace for where error was thrown (only available on V8)
    Error.captureStackTrace(this, this.constructor);

    // Set the prototype explicitly
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

/**
 * 400 Bad Request
 * Used when client sends invalid data
 */
export class BadRequestError extends AppError {
  constructor(message: string = "Bad Request", errorCode?: string) {
    super(message, 400, true, errorCode);
    Object.setPrototypeOf(this, BadRequestError.prototype);
  }
}

/**
 * 401 Unauthorized
 * Used when authentication is required but missing or invalid
 */
export class UnauthorizedError extends AppError {
  constructor(message: string = "Unauthorized", errorCode?: string) {
    super(message, 401, true, errorCode);
    Object.setPrototypeOf(this, UnauthorizedError.prototype);
  }
}

/**
 * 403 Forbidden
 * Used when user doesn't have permission to access resource
 */
export class ForbiddenError extends AppError {
  constructor(message: string = "Forbidden", errorCode?: string) {
    super(message, 403, true, errorCode);
    Object.setPrototypeOf(this, ForbiddenError.prototype);
  }
}

/**
 * 404 Not Found
 * Used when requested resource doesn't exist
 */
export class NotFoundError extends AppError {
  constructor(message: string = "Resource not found", errorCode?: string) {
    super(message, 404, true, errorCode);
    Object.setPrototypeOf(this, NotFoundError.prototype);
  }
}

/**
 * 409 Conflict
 * Used when there's a conflict with current state (e.g., duplicate resource)
 */
export class ConflictError extends AppError {
  constructor(message: string = "Conflict", errorCode?: string) {
    super(message, 409, true, errorCode);
    Object.setPrototypeOf(this, ConflictError.prototype);
  }
}

/**
 * 422 Unprocessable Entity
 * Used when request is well-formed but contains semantic errors
 */
export class ValidationError extends AppError {
  public readonly errors?: any[];

  constructor(message: string = "Validation failed", errors?: any[], errorCode?: string) {
    super(message, 422, true, errorCode);
    this.errors = errors;
    Object.setPrototypeOf(this, ValidationError.prototype);
  }
}

/**
 * 500 Internal Server Error
 * Used for unexpected server errors
 */
export class InternalServerError extends AppError {
  constructor(message: string = "Internal server error", errorCode?: string) {
    super(message, 500, false, errorCode);
    Object.setPrototypeOf(this, InternalServerError.prototype);
  }
}

/**
 * 503 Service Unavailable
 * Used when a service dependency is unavailable
 */
export class ServiceUnavailableError extends AppError {
  constructor(message: string = "Service unavailable", errorCode?: string) {
    super(message, 503, true, errorCode);
    Object.setPrototypeOf(this, ServiceUnavailableError.prototype);
  }
}
