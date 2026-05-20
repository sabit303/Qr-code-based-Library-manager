# Centralized Error Handling System

## Overview

This project implements a comprehensive centralized error handling system that provides consistent error responses across all API endpoints. The system uses custom error classes, a global error middleware, and async request handlers to manage errors effectively.

## Architecture

### 1. Custom Error Classes (`src/errors/AppError.ts`)

All custom errors extend the base `AppError` class, which provides:
- HTTP status codes
- Error messages
- Error codes for client identification
- Operational vs programming error distinction

#### Available Error Classes:

| Error Class | Status Code | Use Case |
|------------|-------------|----------|
| `BadRequestError` | 400 | Invalid request data or parameters |
| `UnauthorizedError` | 401 | Missing or invalid authentication |
| `ForbiddenError` | 403 | Insufficient permissions |
| `NotFoundError` | 404 | Resource doesn't exist |
| `ConflictError` | 409 | Resource conflict (e.g., duplicates) |
| `ValidationError` | 422 | Validation failures with detailed errors |
| `InternalServerError` | 500 | Unexpected server errors |
| `ServiceUnavailableError` | 503 | External service unavailable |

### 2. Error Handling Middleware (`src/middlewares/errorHandler.ts`)

The system includes three key middleware functions:

#### `errorHandler`
Global error handling middleware that:
- Catches all errors from routes and middleware
- Formats consistent error responses
- Handles JWT errors automatically
- Handles database errors (duplicates, foreign keys)
- Includes stack traces in development mode
- Logs errors for debugging

#### `notFoundHandler`
Catches requests to non-existent routes (404 errors).

#### `asyncHandler`
Wraps async route handlers to automatically catch and forward errors to the error handler.

### 3. Logger Utility (`src/utils/logger.ts`)

Simple logging utility with levels:
- `ERROR`: Critical errors
- `WARN`: Warnings
- `INFO`: Informational messages
- `DEBUG`: Debugging information

Configure log level via `LOG_LEVEL` environment variable.

## Usage Examples

### In Services

```typescript
import { BadRequestError, NotFoundError, ConflictError } from "../errors/AppError.js";

export class BookServices {
    async addNewBook(dto: AddNewBookDTO): Promise<Book> {
        // Validation errors
        if (!dto.Name || dto.Name.trim() === "") {
            throw new BadRequestError("Book name is required");
        }
        
        // Conflict errors
        const existing = await this.bookRepository.search(dto.Name);
        if (existing.some(b => b.AuthorName === dto.AuthorName)) {
            throw new ConflictError("A book with the same name and author already exists");
        }
        
        // Business logic continues...
    }
    
    async removeBook(id: string): Promise<boolean> {
        const book = await this.bookRepository.getById(id);
        
        // Not found errors
        if (!book) {
            throw new NotFoundError("Book not found");
        }
        
        return this.bookRepository.removeBook(id);
    }
}
```

### In Controllers

Controllers use the `asyncHandler` wrapper to automatically catch errors:

```typescript
import { asyncHandler } from "../middlewares/errorHandler.js";
import { NotFoundError } from "../errors/AppError.js";

export class BookController {
    constructor(private bookService: BookServices) {}

    // Use asyncHandler and arrow functions
    getById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
        const { id } = req.params;
        const book = await this.bookService.getById(id);
        
        if (!book) {
            throw new NotFoundError("Book not found");
        }

        res.status(200).json({
            success: true,
            data: book
        });
    });
    
    // No try-catch needed - asyncHandler handles it!
}
```

### In Middlewares

```typescript
import { UnauthorizedError, ForbiddenError } from "../errors/AppError.js";

export function authMiddleware(req: Request, res: Response, next: NextFunction) {
    const token = req.headers.authorization?.split(" ")[1];
    
    if (!token) {
        throw new UnauthorizedError("No token provided");
    }
    
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET!);
        req.user = decoded;
        next();
    } catch (error) {
        throw new UnauthorizedError("Invalid or expired token");
    }
}

export class AuthorizeRole {
    canAccess(...allowedRoles: string[]) {
        return (req: Request, res: Response, next: NextFunction) => {
            if (!req.user) {
                throw new UnauthorizedError("Authentication required");
            }
            
            if (!allowedRoles.includes(req.user.role)) {
                throw new ForbiddenError(`Access denied. Required roles: ${allowedRoles.join(', ')}`);
            }
            
            next();
        };
    }
}
```

## Error Response Format

All errors return a consistent JSON structure:

### Success Response
```json
{
    "success": true,
    "data": { /* response data */ },
    "message": "Operation completed successfully"
}
```

### Error Response
```json
{
    "success": false,
    "message": "Error description",
    "errorCode": "ERROR_CODE",
    "errors": [ /* optional validation errors */ ],
    "stack": "..." // only in development
}
```

### Example Error Responses

#### 400 Bad Request
```json
{
    "success": false,
    "message": "Book name is required",
    "errorCode": null
}
```

#### 401 Unauthorized
```json
{
    "success": false,
    "message": "Invalid or expired token",
    "errorCode": null
}
```

#### 403 Forbidden
```json
{
    "success": false,
    "message": "Access denied. Required roles: librarian, admin",
    "errorCode": null
}
```

#### 404 Not Found
```json
{
    "success": false,
    "message": "Book not found",
    "errorCode": null
}
```

#### 409 Conflict
```json
{
    "success": false,
    "message": "A book with the same name and author already exists",
    "errorCode": null
}
```

#### 422 Validation Error
```json
{
    "success": false,
    "message": "Missing required fields",
    "errorCode": null,
    "errors": [
        { "field": "Name", "message": "Name is required" },
        { "field": "Email", "message": "Email is required" }
    ]
}
```

#### 500 Internal Server Error
```json
{
    "success": false,
    "message": "An unexpected error occurred",
    "errorCode": "INTERNAL_ERROR"
}
```

## Application Setup

The error handling middleware is registered in `src/app.ts`:

```typescript
import { errorHandler, notFoundHandler } from "./middlewares/errorHandler.js";

const app: Application = express();

// ... middleware and routes ...

// 404 handler - must be after all routes
app.use(notFoundHandler);

// Global error handler - must be last
app.use(errorHandler);

export default app;
```

## Best Practices

### 1. Choose the Right Error Class
- Use specific error classes that match the HTTP status code
- `BadRequestError` for invalid input
- `NotFoundError` for missing resources
- `ForbiddenError` for permission issues
- `UnauthorizedError` for authentication failures

### 2. Provide Descriptive Messages
```typescript
// ❌ Bad
throw new NotFoundError("Not found");

// ✅ Good
throw new NotFoundError("Book not found");
throw new NotFoundError(`Student with ID ${id} not found`);
```

### 3. Use asyncHandler for All Async Routes
```typescript
// ✅ Correct
getById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    // Your code here
});

// ❌ Incorrect - errors won't be caught
async getById(req: Request, res: Response): Promise<Response> {
    try {
        // Your code here
    } catch (error) {
        // Manual error handling
    }
}
```

### 4. Let Services Throw Errors
Services should throw errors, controllers should catch them via asyncHandler:

```typescript
// Service
async getById(id: string): Promise<Book> {
    const book = await this.repository.findById(id);
    if (!book) {
        throw new NotFoundError("Book not found");
    }
    return book;
}

// Controller
getById = asyncHandler(async (req: Request, res: Response): Promise<void> => {
    const book = await this.service.getById(req.params.id);
    res.status(200).json({ success: true, data: book });
});
```

### 5. Avoid Returning Null in Services
```typescript
// ❌ Bad - returning null requires manual checks
async getBook(id: string): Promise<Book | null> {
    const book = await this.repo.findById(id);
    return book; // might be null
}

// ✅ Good - throw error if not found
async getBook(id: string): Promise<Book> {
    const book = await this.repo.findById(id);
    if (!book) throw new NotFoundError("Book not found");
    return book;
}
```

### 6. Don't Catch Errors Just to Re-throw
```typescript
// ❌ Bad - unnecessary try-catch
async create(dto: CreateDTO): Promise<Book> {
    try {
        return await this.repo.create(dto);
    } catch (error) {
        throw error; // Just let it bubble up!
    }
}

// ✅ Good - let errors propagate
async create(dto: CreateDTO): Promise<Book> {
    return await this.repo.create(dto);
}
```

## Error Codes

You can add custom error codes for client-side error handling:

```typescript
throw new BadRequestError("Invalid email format", "INVALID_EMAIL");
throw new ConflictError("Email already registered", "DUPLICATE_EMAIL");
throw new UnauthorizedError("Token expired", "TOKEN_EXPIRED");
```

Response:
```json
{
    "success": false,
    "message": "Email already registered",
    "errorCode": "DUPLICATE_EMAIL"
}
```

## Environment Variables

- `NODE_ENV`: Set to `development` to include stack traces in error responses
- `LOG_LEVEL`: Control logging verbosity (`ERROR`, `WARN`, `INFO`, `DEBUG`)

## Testing Error Handling

Example test cases:

```typescript
describe("Book Controller", () => {
    it("should return 404 when book not found", async () => {
        const response = await request(app)
            .get("/api/books/invalid-id")
            .expect(404);
        
        expect(response.body).toMatchObject({
            success: false,
            message: "Book not found"
        });
    });
    
    it("should return 400 for invalid input", async () => {
        const response = await request(app)
            .post("/api/books")
            .send({ Name: "" })
            .expect(400);
        
        expect(response.body.message).toBe("Book name is required");
    });
});
```

## Migration Checklist

When migrating existing code to use centralized error handling:

- [ ] Import custom error classes in services
- [ ] Replace `throw new Error()` with specific error classes
- [ ] Replace `return null` with throwing errors
- [ ] Use `asyncHandler` for all controller methods
- [ ] Remove try-catch blocks from controllers
- [ ] Replace manual error responses with throwing errors
- [ ] Update middlewares to throw custom errors
- [ ] Test all error scenarios
- [ ] Update API documentation

## Benefits

1. **Consistency**: All errors follow the same format
2. **Maintainability**: Centralized error logic
3. **Type Safety**: TypeScript error classes
4. **Better DX**: No repetitive try-catch blocks
5. **Client Friendly**: Structured error responses with proper status codes
6. **Debugging**: Automatic error logging and stack traces
7. **Production Ready**: Different behavior for dev/prod environments
