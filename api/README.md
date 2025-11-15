# QR Code Based Library Manager API

## Student Endpoint Documentation

This API follows SOLID principles with clean architecture and **MySQL database integration**.

### SOLID Principles Applied:

1. **Single Responsibility Principle (SRP)**
   - `StudentController`: Handles HTTP requests/responses
   - `StudentService`: Contains business logic
   - `MySQLStudentRepository`: Manages data persistence with MySQL
   - `QRCodeService`: Handles QR code operations

2. **Open/Closed Principle (OCP)**
   - Classes are open for extension but closed for modification
   - Use interfaces for flexibility

3. **Liskov Substitution Principle (LSP)**
   - Repository implements IStudentRepository interface
   - Can easily switch between `StudentRepository` (in-memory) and `MySQLStudentRepository`

4. **Interface Segregation Principle (ISP)**
   - Clean, focused interfaces
   - No unnecessary dependencies

5. **Dependency Inversion Principle (DIP)**
   - Controller depends on Service abstraction
   - Service depends on Repository interface
   - Easy to swap implementations (in-memory ↔ MySQL)

## Prerequisites

- Node.js (v16 or higher)
- MySQL Server (v5.7 or higher)
- npm or yarn

## Installation

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Database
Create a `.env` file in the root directory:
```env
# Server Configuration
PORT=3000

# MySQL Database Configuration
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=library_manager
```

### 3. Setup MySQL Database

**Option A: Using the initialization script**
```bash
npm run db:init
```

**Option B: Manual setup**
```bash
mysql -u root -p < src/config/init-db.sql
```

**Option C: Using MySQL Workbench**
1. Open MySQL Workbench
2. Execute the SQL file: `src/config/init-db.sql`

### 4. Run the Application

**Development mode:**
```bash
npm run dev
```

**Production mode:**
```bash
npm run build
npm start
```

## API Endpoints

### 1. Create Student
```http
POST /api/students
Content-Type: application/json

{
  "Name": "John Doe",
  "Roll": "2021001",
  "Registration": "REG2021001",
  "Department": "Computer Science",
  "Session": "2021-2022",
  "ContactNumber": "+1234567890",
  "Address": "123 Main St"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "Name": "John Doe",
    "Roll": "2021001",
    "Registration": "REG2021001",
    "Department": "Computer Science",
    "Session": "2021-2022",
    "ContactNumber": "+1234567890",
    "Address": "123 Main St",
    "qrCode": "QR-UkVHMjAyMTAwMQ==-1234567890"
  },
  "message": "Student created successfully"
}
```

### 2. Get All Students (with pagination & search)
```http
GET /api/students?page=1&limit=10&search=John
```

**Response:**
```json
{
  "success": true,
  "data": {
    "students": [...],
    "total": 100,
    "page": 1,
    "limit": 10
  }
}
```

### 3. Get Student by ID
```http
GET /api/students/:id
```

### 4. Update Student
```http
PUT /api/students/:id
Content-Type: application/json

{
  "Name": "John Updated",
  "ContactNumber": "+0987654321"
}
```

### 5. Delete Student
```http
DELETE /api/students/:id
```

### 6. Generate QR Code for Student
```http
POST /api/students/:id/qrcode
```

### 7. Get Student by QR Code
```http
GET /api/students/qrcode/:qrCode
```

## Architecture

```
src/
├── config/
│   ├── database.ts          # MySQL connection pool
│   └── init-db.sql          # Database schema
├── Controller/              # HTTP layer (handles requests/responses)
│   └── StudentController.ts
├── Services/                # Business logic layer
│   ├── StudentService.ts
│   └── QRCodeService.ts
├── Repositories/            # Data access layer
│   ├── IStudentRepository.ts       # Interface (abstraction)
│   ├── StudentRepository.ts        # In-memory implementation
│   └── MySQLStudentRepository.ts   # MySQL implementation ✨
├── Entities/                # Domain models
│   └── Student.ts
├── DTOs/                    # Data Transfer Objects
│   └── StudentDTO.ts
├── Routes/                  # Route definitions
│   └── StudentRoutes.ts
├── app.ts                   # Express app configuration
├── server.ts                # Server entry point
└── init-database.ts         # Database initialization script
```

## Database Schema

### Students Table
```sql
CREATE TABLE students (
  id VARCHAR(36) PRIMARY KEY,
  Name VARCHAR(255) NOT NULL,
  Roll VARCHAR(50) NOT NULL UNIQUE,
  Registration VARCHAR(50) NOT NULL UNIQUE,
  Department VARCHAR(100) NOT NULL,
  Session VARCHAR(50) NOT NULL,
  ContactNumber VARCHAR(20),
  Address TEXT,
  qrCode VARCHAR(500) UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

## Testing the API

### Using curl:

**Create a student:**
```bash
curl -X POST http://localhost:3000/api/students \
  -H "Content-Type: application/json" \
  -d '{
    "Name": "Jane Smith",
    "Roll": "2021002",
    "Registration": "REG2021002",
    "Department": "Physics",
    "Session": "2021-2022",
    "ContactNumber": "+1234567890",
    "Address": "456 Oak Ave"
  }'
```

**Get all students:**
```bash
curl http://localhost:3000/api/students
```

**Search students:**
```bash
curl "http://localhost:3000/api/students?search=Jane&page=1&limit=10"
```

**Generate QR code:**
```bash
curl -X POST http://localhost:3000/api/students/1/qrcode
```

## Switching Between In-Memory and MySQL

Thanks to **Dependency Inversion Principle**, you can easily switch between implementations:

**In `src/Routes/StudentRoutes.ts`:**

**For MySQL (current):**
```typescript
import { MySQLStudentRepository } from "../Repositories/MySQLStudentRepository.js";
const studentRepository = new MySQLStudentRepository();
```

**For In-Memory:**
```typescript
import { StudentRepository } from "../Repositories/StudentRepository.js";
const studentRepository = new StudentRepository();
```

## Troubleshooting

### Database Connection Error
- Ensure MySQL is running
- Check `.env` credentials
- Verify database exists: `npm run db:init`

### Port Already in Use
- Change `PORT` in `.env`
- Or kill the process using port 3000

### TypeScript Errors
- Run `npm install` to ensure all dependencies are installed
- Check `tsconfig.json` configuration

## Features

✅ RESTful API design
✅ SOLID principles implementation  
✅ MySQL database integration  
✅ QR code generation  
✅ Pagination & search  
✅ UUID primary keys  
✅ Environment configuration  
✅ Error handling  
✅ TypeScript support  
✅ Dependency injection  
✅ Clean architecture  

## Future Enhancements

- [ ] Input validation middleware
- [ ] JWT authentication
- [ ] Rate limiting
- [ ] API documentation (Swagger)
- [ ] Unit tests
- [ ] Integration tests
- [ ] Logging system
- [ ] Database migrations
- [ ] Connection pooling optimization

### SOLID Principles Applied:

1. **Single Responsibility Principle (SRP)**
   - `StudentController`: Handles HTTP requests/responses
   - `StudentService`: Contains business logic
   - `StudentRepository`: Manages data persistence
   - `QRCodeService`: Handles QR code operations

2. **Open/Closed Principle (OCP)**
   - Classes are open for extension but closed for modification
   - Use interfaces for flexibility

3. **Liskov Substitution Principle (LSP)**
   - Repository implements IStudentRepository interface
   - Can be replaced with database implementation

4. **Interface Segregation Principle (ISP)**
   - Clean, focused interfaces
   - No unnecessary dependencies

5. **Dependency Inversion Principle (DIP)**
   - Controller depends on Service abstraction
   - Service depends on Repository interface

## API Endpoints

### 1. Create Student
```http
POST /api/students
Content-Type: application/json

{
  "Name": "John Doe",
  "Roll": "2021001",
  "Registration": "REG2021001",
  "Department": "Computer Science",
  "Session": "2021-2022",
  "ContactNumber": "+1234567890",
  "Address": "123 Main St"
}
```

### 2. Get All Students (with pagination & search)
```http
GET /api/students?page=1&limit=10&search=John
```

### 3. Get Student by ID
```http
GET /api/students/:id
```

### 4. Update Student
```http
PUT /api/students/:id
Content-Type: application/json

{
  "Name": "John Updated",
  "ContactNumber": "+0987654321"
}
```

### 5. Delete Student
```http
DELETE /api/students/:id
```

### 6. Generate QR Code for Student
```http
POST /api/students/:id/qrcode
```

### 7. Get Student by QR Code
```http
GET /api/students/qrcode/:qrCode
```

## Installation

```bash
# Install dependencies
npm install

# Run in development mode
npm run dev

# Build for production
npm run build

# Run production build
npm start
```

## Architecture

```
src/
├── Controller/       # HTTP layer (handles requests/responses)
├── Services/         # Business logic layer
├── Repositories/     # Data access layer
├── Entities/         # Domain models
├── DTOs/            # Data Transfer Objects
├── Routes/          # Route definitions
├── app.ts           # Express app configuration
└── server.ts        # Server entry point
```

## Testing the API

You can test the API using curl, Postman, or any HTTP client:

```bash
# Health check
curl http://localhost:3000/health

# Create a student
curl -X POST http://localhost:3000/api/students \
  -H "Content-Type: application/json" \
  -d '{
    "Name": "Jane Smith",
    "Roll": "2021002",
    "Registration": "REG2021002",
    "Department": "Physics",
    "Session": "2021-2022",
    "ContactNumber": "+1234567890",
    "Address": "456 Oak Ave"
  }'

# Get all students
curl http://localhost:3000/api/students

# Generate QR code
curl -X POST http://localhost:3000/api/students/1/qrcode
```
