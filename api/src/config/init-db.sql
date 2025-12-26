-- Create database if not exists
CREATE DATABASE IF NOT EXISTS library_manager;

USE library_manager;

-- Create students table
CREATE TABLE IF NOT EXISTS students (
  id VARCHAR(36) PRIMARY KEY,
  Name VARCHAR(255) NOT NULL,
  Roll VARCHAR(50) NOT NULL UNIQUE,
  Registration VARCHAR(50) NOT NULL UNIQUE,
  Department VARCHAR(100) NOT NULL,
  Session VARCHAR(50) NOT NULL,
  ContactNumber VARCHAR(20),
  Address TEXT,
  Email VARCHAR(255) NOT NULL UNIQUE,
  Password VARCHAR(255) NOT NULL,
  qrCode VARCHAR(500) UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_roll (Roll),
  INDEX idx_registration (Registration),
  INDEX idx_qrcode (qrCode),
  INDEX idx_department (Department),
  INDEX idx_email (Email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create librarians table
CREATE TABLE IF NOT EXISTS librarians (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  contact VARCHAR(20),
  email VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create books table
CREATE TABLE IF NOT EXISTS books (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  authorName VARCHAR(255) NOT NULL,
  edition VARCHAR(50),
  genre VARCHAR(100),
  totalCopies INT NOT NULL DEFAULT 0,
  availableCopies INT NOT NULL DEFAULT 0,
  qrCode VARCHAR(500) UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_name (name),
  INDEX idx_author (authorName),
  INDEX idx_genre (genre),
  INDEX idx_qrcode (qrCode)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  studentReg VARCHAR(50) NOT NULL,
  bookId VARCHAR(36) NOT NULL,
  librarianId VARCHAR(36),
  borrowedDate DATETIME,
  dueDate DATETIME,
  returnDate DATETIME,
  createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status ENUM('REQUESTED', 'ISSUED', 'RETURNED', 'OVERDUE') NOT NULL DEFAULT 'REQUESTED',
  lateFee DECIMAL(10, 2) DEFAULT 0.00,
  INDEX idx_student (studentReg),
  INDEX idx_book (bookId),
  INDEX idx_status (status),
  INDEX idx_borrowedDate (borrowedDate),
  INDEX idx_dueDate (dueDate),
  FOREIGN KEY (studentReg) REFERENCES students(Registration) ON DELETE CASCADE,
  FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
