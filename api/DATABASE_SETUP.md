# MySQL Database Setup Instructions

## Prerequisites
- MySQL Server installed on your machine
- MySQL running on localhost:3306 (or configure your own settings in `.env`)

## Setup Steps

### 1. Install MySQL
Download and install MySQL from: https://dev.mysql.com/downloads/mysql/

### 2. Configure Environment Variables
Copy `.env.example` to `.env` and update your database credentials:
```bash
cp .env.example .env
```

Edit `.env`:
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=library_manager
```

### 3. Create Database and Tables

#### Option A: Using MySQL Command Line
```bash
mysql -u root -p < src/config/init-db.sql
```

#### Option B: Using MySQL Workbench or phpMyAdmin
1. Open MySQL Workbench
2. Connect to your MySQL server
3. Open and execute the SQL file: `src/config/init-db.sql`

#### Option C: Manual SQL Execution
```sql
CREATE DATABASE IF NOT EXISTS library_manager;

USE library_manager;

CREATE TABLE IF NOT EXISTS students (
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
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_roll (Roll),
  INDEX idx_registration (Registration),
  INDEX idx_qrcode (qrCode),
  INDEX idx_department (Department)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### 4. Run the Application
```bash
npm run dev
```

## Verify Database Connection
If the database is configured correctly, you should see:
```
✅ MySQL Database connected successfully
🚀 Server is running on port 3000
```

## Troubleshooting

### Connection Error
If you see connection errors:
1. Make sure MySQL is running
2. Check your credentials in `.env`
3. Verify the database exists
4. Check if port 3306 is open

### Authentication Error
If using MySQL 8.0+ and getting authentication errors:
```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'your_password';
FLUSH PRIVILEGES;
```

## Database Schema

The `students` table includes:
- `id` - Unique identifier (UUID)
- `Name` - Student name
- `Roll` - Roll number (unique)
- `Registration` - Registration number (unique)
- `Department` - Department name
- `Session` - Academic session
- `ContactNumber` - Phone number
- `Address` - Physical address
- `qrCode` - QR code identifier (unique)
- `created_at` - Timestamp of creation
- `updated_at` - Timestamp of last update

## SOLID Principles with MySQL

The implementation maintains SOLID principles:
- **Dependency Inversion**: `StudentService` depends on `IStudentRepository` interface
- **Open/Closed**: Easy to switch between `StudentRepository` (in-memory) and `MySQLStudentRepository`
- **Liskov Substitution**: Both repositories implement the same interface
- Simply change the repository in `StudentRoutes.ts` to switch between implementations
