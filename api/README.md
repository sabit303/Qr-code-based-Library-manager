# QR Code Based Library Manager API

A RESTful API for managing library operations including books, students, librarians, and book borrowing transactions with QR code integration.

## Features

✅ Complete library management system
✅ RESTful API design with JWT authentication
✅ SOLID principles implementation
✅ MySQL database integration
✅ QR code generation for students
✅ Book borrowing system with transaction tracking
✅ Role-based access control (Student/Librarian)
✅ Pagination & search functionality
✅ TypeScript support
✅ Clean architecture with dependency injection
✅ Environment-based configuration

## Prerequisites

### For Docker (Recommended)
- Docker
- Docker Compose

### For Local Development (Without Docker)
- Node.js (v16 or higher)
- MySQL Server (v5.7 or higher)
- npm or yarn

## Installation

### Option A: Using Docker (Recommended)

#### 1. Configure Environment
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

# JWT Configuration
JWT_SECRET=your_secret_key_here
JWT_EXPIRES_IN=7d
```

#### 2. Start with Docker

```bash
# Build the Docker image
docker-compose build

# Start MySQL database and API server
docker-compose up -d


```

The database will be automatically initialized with the schema on first run.

**Useful Docker commands:**
```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f

# Stop containers
docker-compose down

# Restart containers
docker-compose restart
```

---

### Option B: Local Development (Without Docker)

#### 1. Install Dependencies
```bash
npm install
```

#### 2. Configure Environment
Create a `.env` file (same as above)

#### 3. Setup MySQL Database
Ensure MySQL is running locally and create the database:
```bash
mysql -u root -p < src/config/init-db.sql
```

#### 4. Run the Application

**Development mode:**
```bash
npm run dev
```

**Production mode:**
```bash
npm run build
npm start
```

## Architecture

```
src/
├── config/
│   ├── database.ts          # MySQL connection pool
│   └── init-db.sql          # Database schema & initial data
├── Controller/              # HTTP layer (handles requests/responses)
│   ├── authController.ts
│   ├── BookController.ts
│   ├── BorrowController.ts
│   ├── LibrarianController.ts
│   └── StudentController.ts
├── Services/                # Business logic layer
│   ├── BookServices.ts
│   ├── BorrowServices.ts
│   ├── LibrarianService.ts
│   ├── LoginService.ts
│   ├── QRCodeService.ts
│   └── StudentService.ts
├── Repositories/            # Data access layer
│   ├── MySQLBookRepository.ts
│   ├── MySQLBorrowRepository.ts
│   ├── MySQLLibrarianRepository.ts
│   └── MySQLStudentRepository.ts
├── Interfaces/              # Repository interfaces
│   ├── IBookRepository.ts
│   ├── IBorrowRepository.ts
│   ├── ILibrarianRepository.ts
│   └── IStudentRepository.ts
├── Entities/                # Domain models
│   ├── Book.ts
│   ├── Librarian.ts
│   ├── Student.ts
│   └── Transaction.ts
├── DTOs/                    # Data Transfer Objects
│   ├── BookDTO.ts
│   ├── LibrarianDTO.ts
│   ├── LoggedInDTO.ts
│   ├── LoginDTO.ts
│   └── StudentDTO.ts
├── middlewares/
│   ├── authMiddleware.ts
│   ├── authorizeRoleMiddleware.ts
│   └── requestLogger.ts
├── Routes/                  # Route definitions
│   ├── AuthRoutes.ts
│   ├── BookRoutes.ts
│   ├── BorrowRoutes.ts
│   ├── LibrarianRoutes.ts
│   └── StudentRoutes.ts
├── Helper/
│   └── passHash.ts          # Password hashing utilities
├── types/
│   └── express.d.ts         # TypeScript type definitions
├── validators/              # Input validation
├── app.ts                   # Express app configuration
├── server.ts                # Server entry point
└── init-database.ts         # Database initialization script
```

## API Endpoints

### Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "OK",
  "message": "Server is running"
}
```

---

### Authentication

#### Register/Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "student123",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid",
      "username": "student123",
      "role": "student"
    }
  }
}
```

---

### Students

#### Create Student
```http
POST /api/students
Content-Type: application/json
Authorization: Bearer <token>

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

#### Get All Students
```http
GET /api/students?page=1&limit=10&search=John
Authorization: Bearer <token>
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

#### Get Student by ID
```http
GET /api/students/:id
Authorization: Bearer <token>
```

#### Update Student
```http
PUT /api/students/:id
Content-Type: application/json
Authorization: Bearer <token>

{
  "Name": "John Updated",
  "ContactNumber": "+0987654321"
}
```

#### Delete Student
```http
DELETE /api/students/:id
Authorization: Bearer <token>
```

#### Generate QR Code for Student
```http
POST /api/students/:id/qrcode
Authorization: Bearer <token>
```

#### Get Student by QR Code
```http
GET /api/students/qrcode/:qrCode
Authorization: Bearer <token>
```

---

### Books

#### Create Book
```http
POST /api/books
Content-Type: application/json
Authorization: Bearer <token>

{
  "title": "Introduction to Algorithms",
  "author": "Thomas H. Cormen",
  "isbn": "978-0262033848",
  "publisher": "MIT Press",
  "publishedYear": 2009,
  "category": "Computer Science",
  "totalCopies": 5,
  "availableCopies": 5
}
```

#### Get All Books
```http
GET /api/books?page=1&limit=10&search=algorithm
Authorization: Bearer <token>
```

#### Get Book by ID
```http
GET /api/books/:id
Authorization: Bearer <token>
```

#### Update Book
```http
PUT /api/books/:id
Content-Type: application/json
Authorization: Bearer <token>

{
  "totalCopies": 10,
  "availableCopies": 8
}
```

#### Delete Book
```http
DELETE /api/books/:id
Authorization: Bearer <token>
```

---

### Borrow/Return Books

#### Borrow Book
```http
POST /api/borrow
Content-Type: application/json
Authorization: Bearer <token>

{
  "studentId": "uuid-of-student",
  "bookId": "uuid-of-book"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "transactionId": "uuid",
    "studentId": "uuid",
    "bookId": "uuid",
    "borrowDate": "2026-01-08T10:00:00.000Z",
    "dueDate": "2026-01-22T10:00:00.000Z",
    "status": "borrowed"
  },
  "message": "Book borrowed successfully"
}
```

#### Return Book
```http
POST /api/borrow/return
Content-Type: application/json
Authorization: Bearer <token>

{
  "transactionId": "uuid-of-transaction"
}
```

#### Get Borrow History
```http
GET /api/borrow/history/:studentId
Authorization: Bearer <token>
```

#### Get Active Borrows
```http
GET /api/borrow/active
Authorization: Bearer <token>
```

---

### Librarians

#### Create Librarian
```http
POST /api/librarian
Content-Type: application/json
Authorization: Bearer <token>

{
  "username": "librarian1",
  "password": "secure_password",
  "name": "Jane Smith",
  "email": "jane@library.com"
}
```

#### Get All Librarians
```http
GET /api/librarian
Authorization: Bearer <token>
```

#### Get Librarian by ID
```http
GET /api/librarian/:id
Authorization: Bearer <token>
```

#### Update Librarian
```http
PUT /api/librarian/:id
Content-Type: application/json
Authorization: Bearer <token>

{
  "name": "Jane Updated",
  "email": "jane.updated@library.com"
}
```

#### Delete Librarian
```http
DELETE /api/librarian/:id
Authorization: Bearer <token>
```

---

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

### Books Table
```sql
CREATE TABLE books (
  id VARCHAR(36) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  author VARCHAR(255) NOT NULL,
  isbn VARCHAR(20) UNIQUE,
  publisher VARCHAR(255),
  publishedYear INT,
  category VARCHAR(100),
  totalCopies INT NOT NULL DEFAULT 1,
  availableCopies INT NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Librarians Table
```sql
CREATE TABLE librarians (
  id VARCHAR(36) PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE,
  role VARCHAR(50) DEFAULT 'librarian',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Transactions Table
```sql
CREATE TABLE transactions (
  id VARCHAR(36) PRIMARY KEY,
  studentId VARCHAR(36) NOT NULL,
  bookId VARCHAR(36) NOT NULL,
  borrowDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  dueDate TIMESTAMP NOT NULL,
  returnDate TIMESTAMP NULL,
  status ENUM('borrowed', 'returned', 'overdue') DEFAULT 'borrowed',
  FOREIGN KEY (studentId) REFERENCES students(id),
  FOREIGN KEY (bookId) REFERENCES books(id)
);
```

## Testing the API

### Using curl:

**Login:**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "student123",
    "password": "password123"
  }'
```

**Create a student:**
```bash
curl -X POST http://localhost:3000/api/students \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
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
curl -H "Authorization: Bearer YOUR_TOKEN" \
  http://localhost:3000/api/students
```

**Search students:**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:3000/api/students?search=Jane&page=1&limit=10"
```

**Borrow a book:**
```bash
curl -X POST http://localhost:3000/api/borrow \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "studentId": "uuid-of-student",
    "bookId": "uuid-of-book"
  }'
```

### Using Postman:

Import the provided Postman collection file: `Library-Manager.postman_collection.json`

## SOLID Principles Implementation

### 1. Single Responsibility Principle (SRP)
- **Controllers**: Handle HTTP requests/responses only
- **Services**: Contain business logic and orchestration
- **Repositories**: Manage data persistence operations
- **Entities**: Represent domain models

### 2. Open/Closed Principle (OCP)
- Classes are open for extension but closed for modification
- Use interfaces for flexibility and extensibility

### 3. Liskov Substitution Principle (LSP)
- Repositories implement their respective interfaces
- Can easily switch between different implementations (e.g., MySQL ↔ PostgreSQL)

### 4. Interface Segregation Principle (ISP)
- Clean, focused interfaces for each repository
- No unnecessary dependencies or methods

### 5. Dependency Inversion Principle (DIP)
- Controllers depend on Service abstractions
- Services depend on Repository interfaces
- Easy to swap implementations without changing high-level code

## Troubleshooting

### Database Connection Error
- Ensure Docker containers are running: `docker-compose ps`
- Restart containers: `docker-compose restart`
- Check container logs: `docker-compose logs mysql`
- Verify `.env` credentials match docker-compose.yml configuration

### Port Already in Use
- Change `PORT` in `.env` file
- Or kill the process using port 3000:
  - Windows: `netstat -ano | findstr :3000` then `taskkill /PID <PID> /F`
  - Linux/Mac: `lsof -ti:3000 | xargs kill -9`

### TypeScript Errors
- Run `npm install` to ensure all dependencies are installed
- Check `tsconfig.json` configuration
- Clear dist folder: `rm -rf dist/` and rebuild

### JWT Authentication Issues
- Ensure `JWT_SECRET` is set in `.env`
- Check token expiration time in `.env`
- Verify Authorization header format: `Bearer <token>`

## Development Notes

- All routes except `/health` and `/api/auth/login` require JWT authentication
- Use the `Authorization: Bearer <token>` header for authenticated requests
- Passwords are hashed using bcryptjs before storage
- UUIDs are used for all primary keys
- Database connection uses connection pooling for better performance

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit your changes: `git commit -am 'Add feature'`
4. Push to the branch: `git push origin feature-name`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Links

- **Repository**: https://github.com/sabit303/Qr-code-based-Library-manager
- **Issues**: https://github.com/sabit303/Qr-code-based-Library-manager/issues

## Author

arks

---

**Note**: This is a learning project demonstrating clean architecture principles, SOLID design patterns, and RESTful API best practices with TypeScript and MySQL.
